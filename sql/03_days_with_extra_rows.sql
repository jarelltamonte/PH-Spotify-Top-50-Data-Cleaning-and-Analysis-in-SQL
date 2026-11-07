-- QUESTION: Which days do not have exactly 50 rows?
-- DATA:     raw_ph_spotify. The chart is a Top 50, so every day should have
--           exactly 50 rows.
-- METHOD:   Group by day and keep days where the row count is not 50.
-- CAVEATS:  - Only counts rows per day; it does not say why a day is off.
--           - Three of the four days (2024-03-14, 03-16, 03-18) sit right
--             beside the missing days 2024-03-15 and 03-17. That is an
--             observation, not an explanation.
-- FINDING:  4 days have 51 rows instead of 50 (29,154 actual vs 29,150
--           expected from 583 days x 50): 2023-11-20, 2024-03-14,
--           2024-03-16, 2024-03-18. The next query shows what is wrong on them.

SELECT snapshot_date, COUNT(*) AS n
FROM raw_ph_spotify
GROUP BY snapshot_date
HAVING COUNT(*) <> 50
ORDER BY snapshot_date;


-- QUESTION: On those days, are ranks repeated or missing?
-- DATA:     raw_ph_spotify.
-- METHOD:   Compare the row count with the number of distinct ranks per day.
--           A surplus means rows share a rank with another row that day.
--           Ranks 1 to 50 not present on a day are the empty ranks.
-- CAVEATS:  - Cause unknown, and the correct order of songs cannot be
--             recovered from the data, so no row was repaired or picked.
--           - Only 4 of 583 days (0.7%) are affected.
-- FINDING:  Each of the 4 days has 7 to 11 empty ranks and the same number
--           plus one shared by two different songs (surplus 11, 12, 8, 10 =
--           41 shared pairs, 82 rows). The days were excluded in
--           05_clean_table.sql.

SELECT snapshot_date,
       COUNT(*)                              AS n_rows,
       COUNT(DISTINCT daily_rank)            AS distinct_ranks,
       COUNT(*) - COUNT(DISTINCT daily_rank) AS shared_rank_surplus
FROM raw_ph_spotify
GROUP BY snapshot_date
HAVING COUNT(*) <> COUNT(DISTINCT daily_rank)
ORDER BY snapshot_date;