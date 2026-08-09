#!/bin/bash

set -euo pipefail

echo "==========================================="
echo
echo "MC-FPS1 world randomizer"
echo
date
echo
echo "==========================================="
echo
echo

if test -d "/data/world"; then
  echo "=> removing previous world..."
  rm -r "/data/world"
fi
for item in `ls -F "/data/maps" | grep /`; do
  maps+=("$item")
done
if test -z $maps; then
  echo "=> there are no worlds in /data/maps"
  exit 1
fi
value=$(($RANDOM % ${#maps[@]}))
echo "=> copying /data/maps/${maps[$value]} as world directory..."
cp -r "/data/maps/${maps[$value]}" "/data/world"
