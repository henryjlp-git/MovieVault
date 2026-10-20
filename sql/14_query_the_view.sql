SELECT title, release_date, imdb_score, rt_score, avg_user_stars, review_count, genres
FROM movie_summary
ORDER BY imdb_score DESC NULLS LAST
LIMIT 10;
 
