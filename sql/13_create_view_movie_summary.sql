CREATE OR REPLACE VIEW movie_summary
WITH (security_invoker = true) AS
SELECT
  m.movie_id,
  m.title,
  m.release_date,
  m.runtime_min,
  m.poster_url,
  (SELECT er.score FROM external_ratings er
     JOIN rating_sources rs ON rs.source_id = er.source_id
     WHERE er.movie_id = m.movie_id AND rs.name = 'IMDb')            AS imdb_score,
  (SELECT er.score FROM external_ratings er
     JOIN rating_sources rs ON rs.source_id = er.source_id
     WHERE er.movie_id = m.movie_id AND rs.name = 'Rotten Tomatoes') AS rt_score,
  (SELECT ROUND(AVG(r.stars), 2) FROM reviews r
     WHERE r.movie_id = m.movie_id)                                  AS avg_user_stars,
  (SELECT COUNT(*) FROM reviews r
     WHERE r.movie_id = m.movie_id)                                  AS review_count,
  (SELECT STRING_AGG(g.name, ', ' ORDER BY g.name)
     FROM movie_genres mg JOIN genres g ON g.genre_id = mg.genre_id
     WHERE mg.movie_id = m.movie_id)                                 AS genres
FROM movies m;
