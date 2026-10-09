"""
import_movies.py
Loads movies from the OMDb API into the Supabase (PostgreSQL) database.

Reads movie_list.txt (one IMDb ID or title per line), fetches each movie from
OMDb, and inserts it into: movies, genres, movie_genres, external_ratings.
Safe to re-run: existing rows are updated instead of duplicated.

Usage:
    python import_movies.py
    python import_movies.py my_other_list.txt
"""
import os
import re
import sys
import time

import psycopg2
import requests
from dotenv import load_dotenv

load_dotenv()

OMDB_URL = "https://www.omdbapi.com/"
OMDB_KEY = os.environ["OMDB_API_KEY"]


def get_connection():
    # Separate parameters, so special characters in the password need no encoding.
    return psycopg2.connect(
        host=os.environ["DB_HOST"],
        port=os.environ.get("DB_PORT", "5432"),
        dbname=os.environ.get("DB_NAME", "postgres"),
        user=os.environ["DB_USER"],
        password=os.environ["DB_PASSWORD"],
        sslmode="require",
    )


def read_movie_list(path):
    entries = []
    with open(path, encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith("#"):
                entries.append(line)
    return entries


def fetch_from_omdb(entry):
    """entry is an IMDb ID (tt0111161), a title, or 'Title (Year)'."""
    params = {"apikey": OMDB_KEY, "plot": "short", "type": "movie"}
    if re.fullmatch(r"tt\d+", entry):
        params["i"] = entry
    else:
        match = re.fullmatch(r"(.+?)\s*\((\d{4})\)", entry)
        if match:
            params["t"], params["y"] = match.group(1), match.group(2)
        else:
            params["t"] = entry
    resp = requests.get(OMDB_URL, params=params, timeout=15)
    resp.raise_for_status()
    data = resp.json()
    if data.get("Response") != "True":
        raise ValueError(data.get("Error", "Unknown OMDb error"))
    return data


def clean(value):
    """OMDb uses the string 'N/A' for missing values."""
    return None if value in (None, "", "N/A") else value


def parse_runtime(value):
    value = clean(value)
    if not value:
        return None
    match = re.match(r"(\d+)", value)
    minutes = int(match.group(1)) if match else None
    return minutes if minutes and minutes > 0 else None


def parse_date(value):
    """'14 Oct 1994' -> '1994-10-14'"""
    value = clean(value)
    if not value:
        return None
    from datetime import datetime
    try:
        return datetime.strptime(value, "%d %b %Y").date().isoformat()
    except ValueError:
        return None


def parse_float(value):
    value = clean(value)
    try:
        return float(value) if value else None
    except ValueError:
        return None


def parse_int(value):
    value = clean(value)
    return int(value.replace(",", "")) if value else None


def get_rotten_tomatoes(data):
    for rating in data.get("Ratings", []):
        if rating["Source"] == "Rotten Tomatoes":
            return parse_float(rating["Value"].rstrip("%"))
    return None


def save_movie(cur, data, source_ids):
    cur.execute(
        """
        INSERT INTO movies (imdb_id, title, release_date, runtime_min, plot, poster_url)
        VALUES (%s, %s, %s, %s, %s, %s)
        ON CONFLICT (imdb_id) DO UPDATE SET
            title = EXCLUDED.title,
            release_date = EXCLUDED.release_date,
            runtime_min = EXCLUDED.runtime_min,
            plot = EXCLUDED.plot,
            poster_url = EXCLUDED.poster_url
        RETURNING movie_id
        """,
        (
            data["imdbID"],
            data["Title"],
            parse_date(data.get("Released")),
            parse_runtime(data.get("Runtime")),
            clean(data.get("Plot")),
            clean(data.get("Poster")),
        ),
    )
    movie_id = cur.fetchone()[0]

    # Genres: insert if new, then link to the movie
    for name in [g.strip() for g in (clean(data.get("Genre")) or "").split(",") if g.strip()]:
        cur.execute("INSERT INTO genres (name) VALUES (%s) ON CONFLICT (name) DO NOTHING", (name,))
        cur.execute("SELECT genre_id FROM genres WHERE name = %s", (name,))
        genre_id = cur.fetchone()[0]
        cur.execute(
            "INSERT INTO movie_genres (movie_id, genre_id) VALUES (%s, %s) ON CONFLICT DO NOTHING",
            (movie_id, genre_id),
        )

    # External ratings (one row per source)
    ratings = {
        "IMDb": (parse_float(data.get("imdbRating")), parse_int(data.get("imdbVotes"))),
        "Rotten Tomatoes": (get_rotten_tomatoes(data), None),
    }
    for source_name, (score, votes) in ratings.items():
        if score is None:
            continue
        cur.execute(
            """
            INSERT INTO external_ratings (movie_id, source_id, score, vote_count)
            VALUES (%s, %s, %s, %s)
            ON CONFLICT (movie_id, source_id) DO UPDATE SET
                score = EXCLUDED.score,
                vote_count = EXCLUDED.vote_count,
                retrieved_at = now()
            """,
            (movie_id, source_ids[source_name], score, votes),
        )


def main():
    list_path = sys.argv[1] if len(sys.argv) > 1 else "movie_list.txt"
    entries = read_movie_list(list_path)
    print(f"Importing {len(entries)} movies from {list_path}...")

    conn = get_connection()
    with conn.cursor() as cur:
        cur.execute("SELECT name, source_id FROM rating_sources")
        source_ids = dict(cur.fetchall())
    for needed in ("IMDb", "Rotten Tomatoes"):
        if needed not in source_ids:
            sys.exit(f"rating_sources is missing '{needed}'. Run the seed query first.")

    ok, failed = 0, []
    for i, entry in enumerate(entries, start=1):
        try:
            data = fetch_from_omdb(entry)
            with conn.cursor() as cur:
                save_movie(cur, data, source_ids)
            conn.commit()  # one transaction per movie
            ok += 1
            print(f"[{i}/{len(entries)}] OK      {data['Title']}")
        except Exception as e:
            conn.rollback()
            failed.append((entry, str(e)))
            print(f"[{i}/{len(entries)}] FAILED  {entry}: {e}")
        time.sleep(0.2)  # be polite to the API

    conn.close()
    print(f"\nDone. {ok} imported, {len(failed)} failed.")
    for entry, reason in failed:
        print(f"  - {entry}: {reason}")


if __name__ == "__main__":
    main()
