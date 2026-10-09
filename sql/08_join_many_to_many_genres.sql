SELECT m.title,
       STRING_AGG(g.name, ', ' ORDER BY g.name) AS genres
FROM movies m
JOIN movie_genres mg ON mg.movie_id = m.movie_id
JOIN genres g        ON g.genre_id  = mg.genre_id
GROUP BY m.movie_id, m.title
ORDER BY m.title
LIMIT 20;