#!/usr/bin/env bash
set -euo pipefail

# Simula un incidente: parar un DataNode durante unos segundos.
# Evidencia: estado antes/después y report de HDFS.

NN_CONTAINER=${NN_CONTAINER:-namenode}
SLEEP_SEC=${SLEEP_SEC:-20}
DN_CONTAINER=${DN_CONTAINER:-$(docker ps --format '{{.Names}}' | rg -m1 'dnnm|datanode' || true)}

if [[ -z "$DN_CONTAINER" ]]; then
  echo "[incident] ERROR: no se encontró DataNode. Usa DN_CONTAINER=<nombre>"
  exit 1
fi

echo "[incident] DataNode seleccionado: $DN_CONTAINER"
docker exec "$NN_CONTAINER" bash -lc "hdfs dfsadmin -report | head -n 80"

echo "[incident] Parando DataNode por ${SLEEP_SEC}s..."
docker stop "$DN_CONTAINER" >/dev/null
sleep "$SLEEP_SEC"
docker start "$DN_CONTAINER" >/dev/null

echo "[incident] DataNode arrancado. Reporte HDFS:"
docker exec "$NN_CONTAINER" bash -lc "hdfs dfsadmin -report | head -n 80"
echo "[incident] OK"
