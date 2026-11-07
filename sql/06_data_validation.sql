-- QUESTION: Is clean_ph_spotify correct?
-- DATA:     clean_ph_spotify, compared with raw_ph_spotify.
-- METHOD:   14 checks. Each compares an expected value with the actual one:
--             PASS   = actual matches expected
--             REVIEW = actual differs; investigate
--             INFO   = no fixed expectation; record the number
--           Checks cover row counts, 50 rows per day, unique ranks and tracks
--           per day, rank and popularity ranges, NULLs in key columns,
--           audio-feature ranges, and leftover whitespace.
-- CAVEATS:  - Expected values (204 removed, 579 days) are specific to this
--             dataset and cleaning rule; update them if either changes.
--           - Checks 12 and 13 (tempo > 0, time signature 3-7) rely on my
--             understanding of Spotify's conventions, not the dataset docs.
-- FINDING:  [fill in after running; paste the result table]

SELECT check_name, expected, actual,
       CASE WHEN expected IS NULL  THEN 'INFO'
            WHEN expected = actual THEN 'PASS'
            ELSE 'REVIEW' END AS result
FROM (
  SELECT 1 AS n, 'Raw PH rows' AS check_name, NULL::bigint AS expected,
         (SELECT COUNT(*) FROM raw_ph_spotify WHERE country = 'PH') AS actual
  UNION ALL
  SELECT 2, 'Clean rows', NULL,
         (SELECT COUNT(*) FROM clean_ph_spotify)
  UNION ALL
  SELECT 3, 'Rows removed (4 days x 51 rows)', 204,
         (SELECT COUNT(*) FROM raw_ph_spotify WHERE country = 'PH')
           - (SELECT COUNT(*) FROM clean_ph_spotify)
  UNION ALL
  SELECT 4, 'Chart days in clean table (583 - 4 excluded)', 579,
         (SELECT COUNT(DISTINCT snapshot_date) FROM clean_ph_spotify)
  UNION ALL
  SELECT 5, 'Days without exactly 50 rows', 0,
         (SELECT COUNT(*) FROM (
            SELECT snapshot_date FROM clean_ph_spotify
            GROUP BY 1 HAVING COUNT(*) <> 50) x)
  UNION ALL
  SELECT 6, 'Duplicate (date, rank) pairs', 0,
         (SELECT COUNT(*) FROM (
            SELECT 1 FROM clean_ph_spotify
            GROUP BY snapshot_date, daily_rank HAVING COUNT(*) > 1) x)
  UNION ALL
  SELECT 7, 'Duplicate (date, track) pairs', 0,
         (SELECT COUNT(*) FROM (
            SELECT 1 FROM clean_ph_spotify
            GROUP BY snapshot_date, spotify_id HAVING COUNT(*) > 1) x)
  UNION ALL
  SELECT 8, 'Ranks outside 1-50', 0,
         (SELECT COUNT(*) FROM clean_ph_spotify WHERE daily_rank NOT BETWEEN 1 AND 50)
  UNION ALL
  SELECT 9, 'NULLs in spotify_id / snapshot_date / daily_rank', 0,
         (SELECT COUNT(*) FROM clean_ph_spotify
          WHERE spotify_id IS NULL OR snapshot_date IS NULL OR daily_rank IS NULL)
  UNION ALL
  SELECT 10, 'Popularity outside 0-100', 0,
         (SELECT COUNT(*) FROM clean_ph_spotify WHERE popularity NOT BETWEEN 0 AND 100)
  UNION ALL
  SELECT 11, 'Audio features that should be 0-1 but are not', 0,
         (SELECT COUNT(*) FROM clean_ph_spotify
          WHERE danceability NOT BETWEEN 0 AND 1
             OR energy NOT BETWEEN 0 AND 1
             OR speechiness NOT BETWEEN 0 AND 1
             OR acousticness NOT BETWEEN 0 AND 1
             OR instrumentalness NOT BETWEEN 0 AND 1
             OR liveness NOT BETWEEN 0 AND 1
             OR valence NOT BETWEEN 0 AND 1)
  UNION ALL
  SELECT 12, 'Tempo <= 0', 0,
         (SELECT COUNT(*) FROM clean_ph_spotify WHERE tempo <= 0)
  UNION ALL
  SELECT 13, 'Time signature outside 3-7', 0,
         (SELECT COUNT(*) FROM clean_ph_spotify WHERE time_signature NOT BETWEEN 3 AND 7)
  UNION ALL
  SELECT 14, 'Padded text in name or artists', 0,
         (SELECT COUNT(*) FROM clean_ph_spotify
          WHERE name <> TRIM(name) OR artists <> TRIM(artists))
) t
ORDER BY n;