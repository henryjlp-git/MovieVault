SELECT title, release_date, runtime_min
FROM movies
WHERE runtime_min > 150
ORDER BY runtime_min DESC;