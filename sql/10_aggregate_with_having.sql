-- Counts how many movies have each genre and average runtime for genres with at least 3 movies
SELECT g.name AS genre,
       COUNT(*) AS movies,
       ROUND(AVG(m.runtime_min), 1) AS avg_runtime_min
FROM genres g
JOIN movie_genres mg ON mg.genre_id = g.genre_id
JOIN movies m        ON m.movie_id  = mg.movie_id
GROUP BY g.name
HAVING COUNT(*) >= 3
ORDER BY avg_runtime_min DESC;