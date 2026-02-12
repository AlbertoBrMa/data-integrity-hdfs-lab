#!/usr/bin/env bash
set -euo pipefail

NN_CONTAINER=${NN_CONTAINER:-namenode}
DT=${DT:-$(date +%F)}

echo "[fsck] DT=$DT"

run_fsck() {
  local target="$1"
  local tag="$2"
  docker exec "$NN_CONTAINER" bash -lc "hdfs fsck $target -files -blocks -locations > /tmp/fsck_${tag}.txt"
  docker exec "$NN_CONTAINER" bash -lc "c_corrupt=\$(grep -c 'CORRUPT' /tmp/fsck_${tag}.txt || true); \
    c_missing=\$(grep -c 'MISSING' /tmp/fsck_${tag}.txt || true); \
    c_under=\$(grep -c 'UNDER_REPLICATED' /tmp/fsck_${tag}.txt || true); \
    echo 'metric,count' > /tmp/fsck_${tag}_summary.csv; \
    echo 'CORRUPT,'\$c_corrupt >> /tmp/fsck_${tag}_summary.csv; \
    echo 'MISSING,'\$c_missing >> /tmp/fsck_${tag}_summary.csv; \
    echo 'UNDER_REPLICATED,'\$c_under >> /tmp/fsck_${tag}_summary.csv"
  docker exec "$NN_CONTAINER" bash -lc "hdfs dfs -put -f /tmp/fsck_${tag}.txt /audit/fsck/$DT/fsck_${tag}.txt"
  docker exec "$NN_CONTAINER" bash -lc "hdfs dfs -put -f /tmp/fsck_${tag}_summary.csv /audit/fsck/$DT/fsck_${tag}_summary.csv"
}

run_fsck "/data" "data"

if docker exec "$NN_CONTAINER" bash -lc "hdfs dfs -test -d /backup"; then
  run_fsck "/backup" "backup"
fi

echo "[fsck] OK"
