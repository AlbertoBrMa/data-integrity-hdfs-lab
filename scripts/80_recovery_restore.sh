#!/usr/bin/env bash
set -euo pipefail

# Demostrar recuperación restaurando desde /backup hacia /data.

NN_CONTAINER=${NN_CONTAINER:-namenode}
DT=${DT:-$(date +%F)}

echo "[recovery] DT=$DT"

if ! docker exec "$NN_CONTAINER" bash -lc "hdfs dfs -test -d /backup/logs/raw/dt=$DT"; then
  echo "[recovery] ERROR: no existe /backup/logs/raw/dt=$DT"
  exit 1
fi

docker exec "$NN_CONTAINER" bash -lc "hdfs dfs -mkdir -p /data/logs/raw/dt=$DT /data/iot/raw/dt=$DT"
docker exec "$NN_CONTAINER" bash -lc "hdfs dfs -cp -f /backup/logs/raw/dt=$DT/* /data/logs/raw/dt=$DT/"
docker exec "$NN_CONTAINER" bash -lc "hdfs dfs -cp -f /backup/iot/raw/dt=$DT/* /data/iot/raw/dt=$DT/"

DT="$DT" NN_CONTAINER="$NN_CONTAINER" bash scripts/30_fsck_audit.sh
DT="$DT" NN_CONTAINER="$NN_CONTAINER" bash scripts/50_inventory_compare.sh

echo "[recovery] OK"
