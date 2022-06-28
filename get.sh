#!/usr/bin/env bash

set -euo pipefail

if [[ "$#" -eq 0 ]]; then
  echo "USAGE: $0 <year> [year ...]" >&2
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

if ! command -v curl jq &>/dev/null; then
  echo "$0: required: curl, jq" >&2
  exit 1
fi

mkdir -p csv json

BASE_URL="https://www.hasanmap.org"
UA="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36"

if [[ "${#years[*]}" = 0 ]]; then
  echo -n "argument is not given. set '2009-2019' as targetted range? (y[es]/no): "
  read -r resp
  if ! [[ "$resp" =~ ^(y|yes)$ ]]; then
    echo "$0: abort."
    exit 0
  fi
  years=({2009..2019})
fi

echo "[get id-position json]"
for y in "${years[@]}"; do
  echo -n "json/${y}.json..."
  if [ -f "json/${y}.json" ]; then
    echo "skipped!"
  elif [[ "$(
    curl --retry 3 -A "$UA" -s -m 5 -w '%{http_code}' -o /dev/null "${BASE_URL}/data/${y}.json"
  )" != 200 ]]; then
    echo "$0: invalid year -- '${y}'" >&2
    exit 1
  else
    curl --retry 3 -A "$UA" -s -m 5 "${BASE_URL}/data/${y}.json" >"json/${y}.json"
    echo "saved!"
  fi
done

echo "[get date-address-name data]"
for y in "${years[@]}"; do
  if ! [ -f "csv/${y}.csv" ]; then
    echo "id,date,address,name,lon,lat" >"csv/${y}.csv"
  fi

  echo -n "csv/${y}.csv...loading..."$'\r'

  jq -r ".[]|@csv" "json/${y}.json" | tr -d '"' | sed 's/,.*$//' >._all
  jq -srR 'split("\n")|map(split(","))[][0]' "csv/${y}.csv" | sed '1d;/^null$/d' >._fetched
  ids=()
  while IFS=$'\n' read -r line; do ids+=("$line"); done < <(sort ._all ._fetched ._fetched | uniq -u)
  rm ._all ._fetched

  len="${#ids[*]}"
  idx=0
  for id in "${ids[@]}"; do
    read -r lon lat < <(jq -r '.[]|select(.[0]=="'"${id}"'")|.[1]+" "+.[2]' "json/${y}.json")
    echo -n "csv/${y}.csv...[$((++idx))/${len}]: ${id}"$'\r'

    if grep -q "${id}," "csv/${y}.csv" || [ -z "$lon" ] || [ -z "$lat" ]; then
      echo "invalid row(${y}, ${id}): '$lon', '$lat'" | tee -a log
      continue
    fi

    detail="$(
      curl --retry 3 -A "$UA" -s -m 5 -d "hasan_id=${id}" "${BASE_URL}/api/detail.php" |
        head -4 | sed '3d;s_</br>__g;s/\r//g' | tr \\n ,
    )"
    if echo "$detail" | grep -E "X-UA-Compatible|500 Internal Server Error" ||
      [[ "$(echo "${detail}" | grep -o , | wc -l)" != 3 ]]; then
      echo "invalid response(${y}, ${id}): ${detail}" | tee -a log
    else
      echo "${id},${detail}${lon},${lat}" >>"csv/${y}.csv"
    fi
  done
  echo -n $'\033[K'
  echo "csv/${y}.csv...done!"
done
