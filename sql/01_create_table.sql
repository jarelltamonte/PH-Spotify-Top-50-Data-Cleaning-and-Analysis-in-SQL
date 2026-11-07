CREATE TABLE raw_ph_spotify (
  spotify_id text, name text, artists text, daily_rank text,
  daily_movement text, weekly_movement text, country text,
  snapshot_date text, popularity text, is_explicit text,
  duration_ms text, album_name text, album_release_date text,
  danceability text, energy text, key text, loudness text,
  mode text, speechiness text, acousticness text,
  instrumentalness text, liveness text, valence text,
  tempo text, time_signature text
);

SELECT * FROM raw_ph_spotify;