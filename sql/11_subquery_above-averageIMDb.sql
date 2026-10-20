SELECT m.title, er.score
FROM movies m
JOIN external_ratings er ON er.movie_id = m.movie_id
JOIN rating_sources rs   ON rs.source_id = er.source_id
WHERE rs.name = 'IMDb'
  AND er.score > (
    SELECT AVG(er2.score)
    FROM external_ratings er2
    JOIN rating_sources rs2 ON rs2.source_id = er2.source_id
    WHERE rs2.name = 'IMDb'
  )
ORDER BY er.score DESC;
