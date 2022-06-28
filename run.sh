#!/usr/bin/env bash

if ! command -v curl jq &>/dev/null; then
  echo "require: curl, jq" >&2
  exit 1
fi

years=({2009..2019})

echo "[get id-position json]"
for y in "${years[@]}"; do
  if [[ -f "json/${y}.json" ]]; then
    continue
  elif [[ "$(
    curl --retry 3 -A "$UA" -s -m 5 -w '%{http_code}' -o /dev/null "${BASE_URL}/data/${y}.json"
  )" != 200 ]]; then
    echo "$0: invalid year -- '${y}'" >&2
    exit 1
  else
    curl --retry 3 -A "$UA" -s -m 5 "${BASE_URL}/data/${y}.json" >"json/${y}.json"
  fi
done

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

echo "[choose one]"
select y in "${ys[@]}"; do
  f=0
  for i in "${ys[@]}"; do
    if [ "$i" == "$y" ]; then
      f=1
    fi
  done
  if [[ "$f" = 0 ]]; then
    echo "$0: invalid option -- $y" >&2
    exit 1
  fi
  while :; do
    if ./get.sh "$y"; then
      break
    else
      sleep 100
    fi
  done
done
