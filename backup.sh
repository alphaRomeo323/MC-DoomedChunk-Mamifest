#!/bin/bash

set -euo pipefail

echo "==========================================="
echo
echo "Backup for MC-FPS1 environment using RClone"
echo
date
echo
echo "==========================================="
echo
echo

if test -d "/data/backups"; then
  if test -f "/data/rclone.conf"; then
    echo "=> Starting backup."
    rclone --config /data/rclone.conf copy /data/backups backup:/mc_dev/fps1-backup/
    echo "=> Checking if old backup(s) exists."
    cd /data/backups
    old_backups=$(ls -1t *.zip | tail -n+2)
    if [ -n "${old_backups}" ]; then
      echo -e "  => Removing old backup(s):\n'${old_backups}'\n"
      rm ${old_backups}
    else
      echo "=> Old backups not found."
    fi
  echo "=> All Operation Completed Successfully."
  else
  echo "=> rclone.conf doesn't exist."
  cd /data/backups
  old_backups=$(ls -1t *.zip | tail -n+20)
  if [ -n "${old_backups}" ]; then
    echo "=> Removing backups other than latest 20 to prevent storage overflow."
    rm ${old_backups}
    echo "=> Removal complete.(You should NOT rely on this! Use rclone!)"
  fi
else
  echo "=> /backups doesn't exist, backup cancelled"
fi
