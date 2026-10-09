-- Counts how many movies belong to each genre
SELECT g.name AS genre, COUNT(*) AS movie_count
FROM genres g
JOIN movie_genres mg ON mg.genre_id = g.genre_id
GROUP BY g.name
ORDER BY movie_count DESC;