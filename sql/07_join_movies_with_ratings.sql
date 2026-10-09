SELECT m.title, rs.name AS source, er.score, rs.scale_max
FROM movies m
JOIN external_ratings er ON er.movie_id = m.movie_id
JOIN rating_sources rs   ON rs.source_id = er.source_id
WHERE m.title = 'Inception'
ORDER BY rs.name;