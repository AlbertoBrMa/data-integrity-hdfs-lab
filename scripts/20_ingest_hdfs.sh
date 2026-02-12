#!/usr/bin/env bash
set -euo pipefail

NN_CONTAINER=${NN_CONTAINER:-namenode}
DT=${DT:-$(date +%F)}
LOCAL_DIR=${LOCAL_DIR:-./data_local/$DT}

echo "[ingest] DT=$DT"
echo "[ingest] Local dir=$LOCAL_DIR"

LOG_FILE="$LOCAL_DIR/logs_${DT//-/}.log"
IOT_FILE="$LOCAL_DIR/iot_${DT//-/}.jsonl"

if [[ ! -f "$LOG_FILE" || ! -f "$IOT_FILE" ]]; then
  echo "[ingest] ERROR: no se encuentran los ficheros en $LOCAL_DIR"
  echo "[ingest] Esperados: $LOG_FILE y $IOT_FILE"
  exit 1
fi

echo "[ingest] Copiando al contenedor $NN_CONTAINER:/tmp"
docker cp "$LOG_FILE" "$NN_CONTAINER:/tmp/$(basename "$LOG_FILE")"
docker cp "$IOT_FILE" "$NN_CONTAINER:/tmp/$(basename "$IOT_FILE")"

docker exec "$NN_CONTAINER" bash -lc "hdfs dfs -put -f /tmp/$(basename "$LOG_FILE") /data/logs/raw/dt=$DT/"
docker exec "$NN_CONTAINER" bash -lc "hdfs dfs -put -f /tmp/$(basename "$IOT_FILE") /data/iot/raw/dt=$DT/"

docker exec "$NN_CONTAINER" bash -lc "hdfs dfs -ls -R /data"
docker exec "$NN_CONTAINER" bash -lc "hdfs dfs -du -h /data"
echo "[ingest] OK"
