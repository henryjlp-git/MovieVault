INSERT INTO reviews (user_id, movie_id, stars, body)
SELECT (SELECT user_id FROM users LIMIT 1),
       (SELECT movie_id FROM movies WHERE title = 'Inception'),
       9, 'Mind-bending and beautifully shot.';

SELECT m.title, u.username, r.stars, r.body, r.created_at
FROM reviews r
JOIN movies m ON m.movie_id = r.movie_id
JOIN users u  ON u.user_id  = r.user_id;

UPDATE reviews
SET stars = 8, body = 'Great, but the ending left me confused.', updated_at = now()
WHERE movie_id = (SELECT movie_id FROM movies WHERE title = 'Inception');

DELETE FROM reviews
WHERE movie_id = (SELECT movie_id FROM movies WHERE title = 'Inception');
