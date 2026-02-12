#!/usr/bin/env bash
set -euo pipefail

# Variante A (base): copiar dentro del mismo clúster a /backup
# Variante B (avanzada): usar DistCp hacia otro clúster (no incluido en este starter)

NN_CONTAINER=${NN_CONTAINER:-namenode}
DT=${DT:-$(date +%F)}

echo "[backup] DT=$DT"

docker exec "$NN_CONTAINER" bash -lc "hdfs dfs -mkdir -p /backup/logs/raw/dt=$DT /backup/iot/raw/dt=$DT"

docker exec "$NN_CONTAINER" bash -lc "hdfs dfs -cp -f /data/logs/raw/dt=$DT/* /backup/logs/raw/dt=$DT/"
docker exec "$NN_CONTAINER" bash -lc "hdfs dfs -cp -f /data/iot/raw/dt=$DT/* /backup/iot/raw/dt=$DT/"

docker exec "$NN_CONTAINER" bash -lc "hdfs dfs -ls -R /backup/logs/raw/dt=$DT"
docker exec "$NN_CONTAINER" bash -lc "hdfs dfs -ls -R /backup/iot/raw/dt=$DT"
echo "[backup] OK"
