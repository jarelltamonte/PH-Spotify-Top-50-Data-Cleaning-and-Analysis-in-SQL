-- QUESTION: Which artists appear most on the PH Top 50, and how often in the
--           top 10?
-- DATA:     clean_ph_spotify (28,950 rows, 579 chart days, 2023-10-18 to
--           2025-06-11).
-- METHOD:   - regexp_split_to_table splits each credit on commas, giving one
--             row per artist per song per day; TRIM removes padding.
--           - chart_appearances = artist-days on the chart (one song on the
--             chart for 30 days counts 30).
--           - distinct_songs separates one long-running hit from a broad catalog.
--           - top10_appearances = artist-days at rank 10 or better.
-- CAVEATS:  - Every artist on a collaboration is credited, so totals add up to
--             more than 28,950.
--           - Splitting on commas can cut a name that contains a comma.
--           - One long-running hit can dominate chart_appearances; compare
--             with distinct_songs.
--           - 20 missing days and 4 excluded days are not counted.
--           - Rank-based counts are safe to use because the days with
--             unreliable ranks were removed in 05_clean_table.sql.
-- FINDING:  [fill in after running; paste the top-20 output]

WITH split AS (
  SELECT snapshot_date,
         spotify_id,
         daily_rank,
         TRIM(a) AS artist
  FROM clean_ph_spotify,
       LATERAL regexp_split_to_table(artists, ',') AS a
)
SELECT artist,
       COUNT(*) AS chart_appearances,
       COUNT(DISTINCT spotify_id) AS distinct_songs,
       COUNT(*) FILTER (WHERE daily_rank <= 10) AS top10_appearances
FROM split
GROUP BY artist
ORDER BY chart_appearances DESC
LIMIT 20;