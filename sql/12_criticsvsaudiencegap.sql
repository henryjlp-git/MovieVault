SELECT m.title,
       imdb.score * 10 AS imdb_pct,
       rt.score        AS rt_pct,
       ABS(imdb.score * 10 - rt.score) AS gap
FROM movies m
JOIN external_ratings imdb ON imdb.movie_id = m.movie_id
  AND imdb.source_id = (SELECT source_id FROM rating_sources WHERE name = 'IMDb')
JOIN external_ratings rt ON rt.movie_id = m.movie_id
  AND rt.source_id = (SELECT source_id FROM rating_sources WHERE name = 'Rotten Tomatoes')
ORDER BY gap DESC
LIMIT 10;
