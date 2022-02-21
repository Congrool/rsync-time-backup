#!/bin/bash
CMDDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
ROOTBACKUPDIR="/mnt/backup/root"
HOMEBACKUPDIR="/mnt/backup/home"
BOOTBACKUPDIR="/mnt/backup/boot"
EFIBACKUPDIR="${BOOTBACKUPDIR}/efi"
ROOTSTRATEGY="1:1 30:7 365:30"
HOMESTRATEGY="1:1 30:7 365:30"
BOOTSTRATEGY="1:1 7:7 30:30 365:180"

function mount_dev() {
  if ! $(grep -qs /mnt/backup /proc/mounts) ; then
    echo "$(date): mount /dev/sdc1 at /mnt/backup for backup"
    mount /dev/sdc1 /mnt/backup
    if [[ $? -ne 0 ]]; then 
      echo "$(date): failed to mount /dev/sdc1"
      exit -1
    fi
  fi
  echo "$(date): /dev/sdc1 has mount"
}

function umount_dev() {
  if $(grep -qs /mnt/backup /proc/mounts); then 
    echo "$(date): umount dev at /mnt/backup for backup"
    umount /mnt/backup
    if [[ $? -ne 0 ]]; then
      echo "$(date): failed to umount dev at /mnt/backup"
      exit -1
    fi
  fi
  echo "$(date): no dev mount at /mnt/backup"
}

function run() {
  CMD="${1}"
  while : ; do
    if $(grep -qs /mnt/backup /proc/mounts); then
      echo "$(date): backup root directory to ${ROOTBACKUPDIR}"
      $CMD --strategy "${ROOTSTRATEGY}" / ${ROOTBACKUPDIR} ${CMDDIR}/exclude-files.txt
      echo "$(date): backup home directory to ${HOMEBACKUPDIR}"
      $CMD --strategy "${HOMESTRATEGY}" /home ${HOMEBACKUPDIR} ${CMDDIR}/exclude-files.txt
      echo "$(date): backup boot directory to ${BOOTBACKUPDIR}"
      $CMD --strategy "${BOOTSTRATEGY}" /boot ${BOOTBACKUPDIR} ${CMDDIR}/exclude-files.txt 
      $CMD --strategy "${BOOTSTRATEGY}" /boot/efi ${EFIBACKUPDIR} ${CMDDIR}/exclude-files.txt
      break
    else
      echo "$(date): no dev mounted on /mnt/backup, retry after 10min"
      sleep 10m
      continue
    fi
  done
  echo "$(date): backup successfully"
}

function rsync() {
  mount_dev
  local CMD="${CMDDIR}/rsync_tmbackup.sh "
  run "${CMD}"
  umount_dev
}

function dryrun_rsync() {
  mount_dev
  local CMD=${CMDDIR}/'rsync_tmbackup.sh --rsync-append-flags "--dry-run"'
  run "${CMD}"
  umount_dev
}

"$@"
