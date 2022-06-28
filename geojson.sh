#!/usr/bin/env bash

set -euo pipefail

if [[ "$#" -eq 0 ]]; then
  echo "USAGE: $0 <year> [year ...]" >&2
  exit 1
fi

if ! command -v jq &>/dev/null; then
  echo "require: jq" >&2
  exit 1
fi

years=()
for i in "$@"; do
  if [[ "$i" =~ ^[0-9]{4}$ ]]; then
    years+=("$i")
  else
    echo "$0: invalid argument -- '$i'" >&2
    exit 1
  fi
done

mkdir -p geojson

echo "[generate geojson from csv]"

for y in "$@"; do
  i="csv/${y}.csv"
  if ! [ -f "$i" ]; then
    echo "$0: not found -- '$i'" >&2
    exit 1
  fi
  echo "${i} -> ${i//csv/geojson}"
  jq -srR '

  [split("\n")[1:]|map(split(","))[]|select(.|length==6)]|
  map({
    "geometry": {"coordinates": [(.[5]|tonumber), (.[4]|tonumber)], "type": "Point"},
    "properties": {
      "Google Maps URL": ("https://www.google.com/maps?q="+.[4]+","+.[5]),
      "Location": {
        "Address": .[2],
        "Business Name": .[3],
        "Geo Coordinates": {
          "Latitude": .[4],
          "Longitude": .[5]
        }
      },
      "Address": .[2],
      "Hasan ID": .[0],
      "Hasan Date": .[1],
      "Hasan Name": .[3],
      "Updated": "'"$(date -u +"%Y-%m-%dT%H:%M:%SZ")"'",
      "Title": .[3],
      "Published": "'"$(date -u +"%Y-%m-%dT%H:%M:%SZ")"'"
    },
    "type": "Feature"
  }) | {"type": "FeatureCollection", "features": .}

  ' <(cat "$i") >"${i//csv/geojson}"
done
echo "done!"
