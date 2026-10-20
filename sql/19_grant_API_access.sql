-- Let the website's roles read the view and the tables behind it
GRANT USAGE ON SCHEMA public TO anon, authenticated;

GRANT SELECT ON movie_summary TO anon, authenticated;
GRANT SELECT ON movies, genres, movie_genres, people, movie_credits,
                rating_sources, external_ratings, users, reviews
  TO anon, authenticated;

-- Logged-in users can post reviews (RLS still limits them to their own)
GRANT INSERT ON reviews TO authenticated;
