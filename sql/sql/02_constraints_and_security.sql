-- CHECK constraints
ALTER TABLE movies
  ADD CONSTRAINT chk_movies_runtime_positive CHECK (runtime_min > 0);
ALTER TABLE reviews
  ADD CONSTRAINT chk_reviews_stars_range CHECK (stars BETWEEN 1 AND 10);
ALTER TABLE external_ratings
  ADD CONSTRAINT chk_ratings_score_nonnegative CHECK (score >= 0);

-- Tie users to Supabase logins
ALTER TABLE users
  ADD CONSTRAINT fk_users_auth
  FOREIGN KEY (user_id) REFERENCES auth.users (id) ON DELETE CASCADE;

-- Auto-create a users row on sign-up
CREATE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = ''
AS $$
BEGIN
  INSERT INTO public.users (user_id, username)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data ->> 'username', split_part(NEW.email, '@', 1))
  );
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Row-level security
ALTER TABLE movies           ENABLE ROW LEVEL SECURITY;
ALTER TABLE genres           ENABLE ROW LEVEL SECURITY;
ALTER TABLE movie_genres     ENABLE ROW LEVEL SECURITY;
ALTER TABLE people           ENABLE ROW LEVEL SECURITY;
ALTER TABLE movie_credits    ENABLE ROW LEVEL SECURITY;
ALTER TABLE rating_sources   ENABLE ROW LEVEL SECURITY;
ALTER TABLE external_ratings ENABLE ROW LEVEL SECURITY;
ALTER TABLE users            ENABLE ROW LEVEL SECURITY;
ALTER TABLE reviews          ENABLE ROW LEVEL SECURITY;

CREATE POLICY "public read" ON movies           FOR SELECT USING (true);
CREATE POLICY "public read" ON genres           FOR SELECT USING (true);
CREATE POLICY "public read" ON movie_genres     FOR SELECT USING (true);
CREATE POLICY "public read" ON people           FOR SELECT USING (true);
CREATE POLICY "public read" ON movie_credits    FOR SELECT USING (true);
CREATE POLICY "public read" ON rating_sources   FOR SELECT USING (true);
CREATE POLICY "public read" ON external_ratings FOR SELECT USING (true);
CREATE POLICY "public read" ON users            FOR SELECT USING (true);
CREATE POLICY "public read" ON reviews          FOR SELECT USING (true);

CREATE POLICY "post own review" ON reviews
  FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);
