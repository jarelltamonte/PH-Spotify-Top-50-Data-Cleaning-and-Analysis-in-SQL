-- QUESTION: What does the data look like once types are fixed and the
--           unusable days are removed?
-- DATA:     raw_ph_spotify -> clean_ph_spotify. The raw table is never changed.
-- METHOD:   1. Keep only country = 'PH'.
--           2. Trim whitespace and turn blank text into NULL.
--           3. Cast text columns to real types (int, date, boolean, numeric).
--           4. Exclude any day that does not have exactly 50 rows.
-- CAVEATS:  - The 4 excluded days (2023-11-20, 2024-03-14, 2024-03-16,
--             2024-03-18) have 51 rows, shared ranks and empty ranks, so the
--             true order can't be recovered. That is 4 of 583 days (0.7%).
--           - The 20 missing days are left as gaps, not filled.
--           - album_release_date is cast only when it is a full date;
--             year-only or year-month values become NULL.
-- FINDING:  29,154 raw rows -> 28,950 clean rows; 204 rows removed
--           (4 days x 51 rows). 579 chart days remain.

DROP TABLE IF EXISTS clean_ph_spotify;

CREATE TABLE clean_ph_spotify AS
SELECT
  NULLIF(TRIM(spotify_id), '') AS spotify_id,
  NULLIF(TRIM(name), '') AS name,
  NULLIF(TRIM(artists), '') AS artists,
  daily_rank::int AS daily_rank,
  daily_movement::int AS daily_movement,
  weekly_movement::int AS weekly_movement,
  snapshot_date::date AS snapshot_date,
  popularity::int AS popularity,
  is_explicit::boolean AS is_explicit,
  duration_ms::int AS duration_ms,
  NULLIF(TRIM(album_name), '') AS album_name,
  CASE WHEN album_release_date ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
       THEN album_release_date::date END AS album_release_date,
  danceability::numeric AS danceability,
  energy::numeric AS energy,
  key::int AS key,
  loudness::numeric AS loudness,
  mode::int AS mode,
  speechiness::numeric AS speechiness,
  acousticness::numeric AS acousticness,
  instrumentalness::numeric AS instrumentalness,
  liveness::numeric AS liveness,
  valence::numeric AS valence,
  tempo::numeric AS tempo,
  time_signature::int AS time_signature
FROM raw_ph_spotify
WHERE country = 'PH'
  AND snapshot_date NOT IN (
    SELECT snapshot_date
    FROM raw_ph_spotify
    WHERE country = 'PH'
    GROUP BY snapshot_date
    HAVING COUNT(*) <> 50
  );

SELECT
  (SELECT COUNT(*) FROM raw_ph_spotify WHERE country = 'PH') AS raw_rows,
  (SELECT COUNT(*) FROM clean_ph_spotify) AS clean_rows,
  (SELECT COUNT(*) FROM raw_ph_spotify WHERE country = 'PH')
    - (SELECT COUNT(*) FROM clean_ph_spotify) AS rows_removed;