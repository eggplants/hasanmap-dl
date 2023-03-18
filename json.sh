#!/usr/bin/env bash

if ! command -v curl jq &>/dev/null; then
  echo "require: curl, jq" >&2
  exit 1
fi

years=({2009..2023})
BASE_URL="https://www.hasanmap.org"
UA="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36"
TIMEOUT="30"

mkdir -p "json"

echo "[get id-position json]"
for y in "${years[@]}"; do
  if [[ -f "json/${y}.json" ]]; then
    echo "got already: ${BASE_URL}/data/${y}.json"
  elif [[ "$(
    curl --retry 3 -A "$UA" -s -m "$TIMEOUT" -I -w '%{http_code}' "${BASE_URL}/data/${y}.json" | sed -n '/^[0-9][0-9][0-9]$/p'
  )" != 200 ]]; then
    echo "$0: invalid year -- '${y}'" >&2
    exit 1
  else
    echo "get: ${BASE_URL}/data/${y}.json"
    curl --retry 3 -A "$UA" -s -m "$TIMEOUT" "${BASE_URL}/data/${y}.json" >"json/${y}.json"
  fi
done

echo "[current csv status]"

ys=()
for j in ./json/*.json; do
  y="$(echo "$j" | tr -dc 0-9)"
  ys+=("$y")
  c="csv/${y}.csv"
  if [ -f "$c" ]; then
    n="$(wc -l <"${c}")"
  else
    n=1
  fi
  ((n--))
  t=$(jq ".|length" "${j}")
  echo "[$y]: ${n}/${t} ($(bc -l <<<"scale=2;$n/$t*100")%)"
done
