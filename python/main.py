import os
import pandas as pd

folder = "/Users/macbookairm1/.cache/kagglehub/datasets/asaniczka/top-spotify-songs-in-73-countries-daily-updated/versions/608"
src = os.path.join(folder, "universal_top_spotify_songs.csv")
out = "ph_top50_raw.csv"

first = True
total = kept = 0
min_date = max_date = None

for chunk in pd.read_csv(src, chunksize=100_000, dtype=str):
    total += len(chunk)
    ph = chunk[chunk["country"] == "PH"]
    kept += len(ph)
    if len(ph):
        lo, hi = ph["snapshot_date"].min(), ph["snapshot_date"].max()
        min_date = lo if min_date is None else min(min_date, lo)
        max_date = hi if max_date is None else max(max_date, hi)
    ph.to_csv(out, mode="w" if first else "a", index=False, header=first)
    first = False

print(f"Total rows read: {total:,}")
print(f"PH rows kept:    {kept:,}")
print(f"PH date range:   {min_date} to {max_date}")
print("Columns:", list(ph.columns))