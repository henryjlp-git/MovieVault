INSERT INTO movies (imdb_id, title, runtime_min)
VALUES ('tt9999991', 'Bad Runtime', -5);

UPDATE reviews SET stars = 11
WHERE movie_id = (SELECT movie_id FROM movies WHERE title = 'Inception');

INSERT INTO movies (imdb_id, title)
VALUES ('tt0111161', 'Duplicate Shawshank');

INSERT INTO reviews (user_id, movie_id, stars)
VALUES ((SELECT user_id FROM users LIMIT 1), 999999, 5);
 
