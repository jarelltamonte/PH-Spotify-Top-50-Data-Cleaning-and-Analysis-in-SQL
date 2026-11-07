# PH Spotify Top 50: Data Cleaning and Analysis in SQL

I took a global Spotify chart dataset, filtered it to the Philippines, and used PostgreSQL to profile it, clean it, validate the result, and find which artists dominate the PH Top 50.

**The short version:** the raw data was mostly clean, but not entirely. I found 20 missing chart days and 4 days where the rankings are internally inconsistent. I left the gaps alone, excluded the 4 bad days, and proved the final table is consistent with 14 checks (13 pass, 1 is under review, see below).

## Questions

1. Can this data be trusted for ranking analysis, and what is wrong with it?
2. Which artists have the biggest presence on the Philippine Spotify Top 50?

## Data

- **Source:** Kaggle, "Top Spotify Songs in 73 Countries (Daily Updated)" by asaniczka (version 608).
- **Scope used:** `country = 'PH'` only, 29,154 rows, 25 columns, one row per song per chart day.
- **Date range:** 2023-10-18 to 2025-06-11 (603 calendar days).
- **No stream counts.** The data has chart rank, movement, popularity score, and audio features, but not streams.
- The data file is not included in this repo. Check the license on the Kaggle page before redistributing it.

## Tools

- **Python (pandas):** filtered the 2.1M-row global file to the Philippines in chunks (2,110,316 rows read, 29,154 kept).
- **PostgreSQL (pgAdmin):** everything else.

## Workflow

Run the files in order. Each file has a header with the question, data, method, caveats, and finding.

| File | What it does |
|---|---|
| `01_create_table.sql` | Creates `raw_ph_spotify` with every column as text, so nothing is converted silently |
| `02_missing_days.sql` | Finds calendar days with no data |
| `03_days_with_extra_rows.sql` | Finds days that don't have exactly 50 rows, then shows what is wrong on them |
| `04_multi_artist_rows.sql` | Counts rows that credit more than one artist |
| `05_clean_table.sql` | Builds `clean_ph_spotify` (types fixed, text trimmed, bad days excluded) |
| `06_data_validation.sql` | 14 checks on the clean table |
| `07_top_artist.sql` | Top artists by chart appearances and top-10 appearances |

The raw table is never edited. All fixes happen in the clean table.

## Data quality findings

| Issue | What I found | What I did |
|---|---|---|
| Missing days | 20 days in 5 gaps, so 583 of 603 days (96.7%) have data | Left as gaps. A daily rank snapshot can't be sensibly filled in |
| Days with the wrong row count | 4 days (2023-11-20, 2024-03-14, 2024-03-16, 2024-03-18) have 51 rows instead of 50 | See below |
| Multi-artist credits | 6,518 of 29,154 rows (22.4%) list more than one artist | Split into one row per artist in the analysis |

**Missing days**

| Gap | Days |
|---|---|
| 2024-03-15 | 1 |
| 2024-03-17 | 1 |
| 2024-11-28 to 2024-12-05 | 8 |
| 2024-12-07 to 2024-12-08 | 2 |
| 2025-04-22 to 2025-04-29 | 8 |

I don't know why these days are missing. It looks like gaps in the source's collection, but I couldn't confirm that.

**The 4 days with 51 rows**

| Day | Rows | Distinct ranks | Rows sharing a rank with another row |
|---|---|---|---|
| 2023-11-20 | 51 | 40 | 11 |
| 2024-03-14 | 51 | 39 | 12 |
| 2024-03-16 | 51 | 43 | 8 |
| 2024-03-18 | 51 | 41 | 10 |

On each of these days, 7 to 11 of the ranks from 1 to 50 are empty, and a similar number are shared by two different songs. That means the correct order of songs on those days can't be recovered from the data, and picking a winner for each shared rank would be a guess. I excluded the 4 days: 204 rows, or 0.7% of the data. Three of them sit right next to the missing days of 15 and 17 March 2024. I noticed that but can't say whether the two are related.

## Validation

`06_data_validation.sql` compares expected and actual values for 14 checks on the clean table.

- **Row counts:** 29,154 raw rows, 28,950 clean rows, 204 removed, as expected.
- **579 chart days** remain (583 minus the 4 excluded).
- **Passed:** every remaining day has exactly 50 rows; no duplicate (date, rank) or (date, track) pairs; ranks are within 1 to 50; popularity is within 0 to 100; no NULLs in key columns; audio features that should be 0 to 1 are; tempo is above 0; no leftover whitespace.
- **Under review:** check 13 found 179 rows (of 28,950) with a time signature outside the expected range of 3 to 7. I kept these rows. The time signature isn't used in this analysis, and the 3 to 7 range reflects my understanding of Spotify's convention, not the dataset's documentation. [TODO: add what the values are after running the breakdown query.]

## Findings: top artists

Chart appearances count artist-days on the chart (a song on the chart for 30 days counts 30 for each credited artist). The Top 10 slots across 579 days total 5,790.

| Artist | Chart appearances | Distinct songs | Top-10 appearances | Share of own appearances in top 10 |
|---|---|---|---|---|
| Hev Abi | 2,377 | 12 | 669 | 28% |
| Arthur Nery | 1,284 | 4 | 203 | 16% |
| Cup of Joe | 1,164 | 6 | 298 | 26% |

- **Hev Abi has the biggest presence by a wide margin.** On an average chart day, about 4 of the 50 songs are Hev Abi's (2,377 appearances over 579 days), and 669 top-10 appearances equal roughly 12% of all top-10 slots in the period.
- **Arthur Nery's presence comes from a few long-running songs.** 4 songs produced 1,284 appearances, or about 321 chart days per song on average. Only 16% of those appearances were in the top 10, the lowest share of the three.
- **Cup of Joe converts presence into top-10 positions well.** With fewer songs than Hev Abi it still has 298 top-10 appearances, a 26% share.

All three are Filipino acts, which fits a market where local music has a large share of the chart. That is from general knowledge: the dataset has no nationality field, so I haven't measured the local share.

## Limitations

- **No streams.** "Presence" here means chart appearances, not listening volume.
- **Data ends in June 2025**, so it doesn't show the most recent year.
- **Top 50 only.** Songs below rank 50 aren't visible.
- **Artist credits are split on commas.** A name that contains a comma could be cut in two. Collaborations credit every artist, so appearance counts add up to more than the number of rows.
- **Long-running songs dominate appearance counts.** That's why distinct songs are shown next to them.
- **Missing and excluded days** (24 of 603) aren't counted anywhere.

## Reproduce it

1. Download the dataset from Kaggle (`kagglehub` works).
2. Filter to `country == 'PH'` with pandas, reading in chunks (the full file is about 500 MB).
3. Import the filtered CSV into the table created by `01_create_table.sql`.
4. Run files `02` to `07` in order.

## Next steps

- How long songs stay on the PH chart (using the gaps documented above)
- A defined local vs. international split and its share of the Top 50 over time
- Whether audio features such as tempo relate to chart position, tested at the track level
