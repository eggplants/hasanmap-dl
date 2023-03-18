# hasanmap-dl

<https://www.hasanmap.org> Data Downloader

## Note

Non-private use or republication of acquired data is not recommended as it may be illegal.

## Usage

```bash
git clone --depth 1 https://github.com/eggplants/hasanmap-dl
cd hasanmap-dl

# 1. Get json/{2009..2023}.json, which contains hasan ids
./json.sh

# 2. Get csv/{2009..2023}.csv, which contains detailed data of hasan-ed people
./csv.sh <year>

# (optional) Convert csv into geojson
./geojson.sh <year>

# (optional) Sort csv
./sort.sh <year>
```
