BEGIN;
 
INSERT INTO movies (imdb_id, title, runtime_min)
VALUES ('tt0000001', 'Transaction Demo Movie', 90);
 
INSERT INTO movie_genres (movie_id, genre_id)
VALUES ((SELECT movie_id FROM movies WHERE imdb_id = 'tt0000001'), 999999);
 
COMMIT;

SELECT * FROM movies WHERE imdb_id = 'tt0000001';
