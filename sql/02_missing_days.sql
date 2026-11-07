-- QUESTION: Which calendar days have no chart data?
-- DATA:     raw_ph_spotify, compared against every calendar day from
--           2023-10-18 to 2025-06-11 (603 days).
-- METHOD:   - generate_series builds the full calendar.
--           - LEFT JOIN to the dates present; unmatched days are missing.
--           - day minus ROW_NUMBER() is constant within a run of consecutive
--             days, so grouping on it collapses missing days into gaps
--             (gaps-and-islands).
-- CAVEATS:  - The cause of the gaps is unknown. This looks like gaps in the
--             source's daily collection, but that is not confirmed.
--           - Gaps are left as gaps, not filled: a daily rank snapshot cannot
--             be sensibly imputed.
--           - Any "days on chart" count that spans a gap will be short by the
--             missing days.
--           - The date range is hardcoded.
-- FINDING:  20 missing days in 5 gaps, so 583 of 603 days (96.7%) have data:
--             2024-03-15            (1 day)
--             2024-03-17            (1 day)
--             2024-11-28 to 2024-12-05 (8 days)
--             2024-12-07 to 2024-12-08 (2 days)
--             2025-04-22 to 2025-04-29 (8 days)

WITH d AS (
  SELECT generate_series('2023-10-18'::date, '2025-06-11'::date, '1 day')::date AS day
),
missing AS (
  SELECT d.day
  FROM d
  LEFT JOIN (SELECT DISTINCT snapshot_date::date AS day FROM raw_ph_spotify) r USING (day)
  WHERE r.day IS NULL
),
grp AS (
  SELECT day, day - (ROW_NUMBER() OVER (ORDER BY day))::int AS g
  FROM missing
)
SELECT
  CASE WHEN MIN(day) = MAX(day)
       THEN MIN(day)::text
       ELSE MIN(day)::text || ' to ' || MAX(day)::text
  END AS missing_period,
  COUNT(*)::text AS gap_length_days
FROM grp
GROUP BY g
ORDER BY MIN(day);