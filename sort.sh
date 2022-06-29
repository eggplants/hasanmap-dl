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

echo "[sort csv]"

for y in "$@"; do
  i="csv/${y}.csv"
  if ! [ -f "$i" ]; then
    echo "$0: not found -- '$i'" >&2
    exit 1
  fi
  echo "${i}"
  head -1 "$i" >_
  sed 1d "$i" | sort -Vk2 -k3 -t ',' | uniq >>_
  mv _ "$i"
done
echo "done!"
