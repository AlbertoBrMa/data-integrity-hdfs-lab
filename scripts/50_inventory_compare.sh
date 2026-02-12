#!/usr/bin/env bash
set -euo pipefail

NN_CONTAINER=${NN_CONTAINER:-namenode}
DT=${DT:-$(date +%F)}

echo "[inventory] DT=$DT"

docker exec "$NN_CONTAINER" bash -lc "
set -euo pipefail
DT='$DT'
SRC_DT=\"/data/logs/raw/dt=\$DT /data/iot/raw/dt=\$DT\"
DST_DT=\"/backup/logs/raw/dt=\$DT /backup/iot/raw/dt=\$DT\"
TMP_DIR=\"/tmp/inventory_\$DT\"
mkdir -p \"\$TMP_DIR\"

INV_DATA=\"\$TMP_DIR/inv_data.csv\"
INV_BACKUP=\"\$TMP_DIR/inv_backup.csv\"
DIFF_TXT=\"\$TMP_DIR/inventory_diff.txt\"
SUMMARY_CSV=\"\$TMP_DIR/inventory_summary.csv\"

hdfs dfs -ls -R \$SRC_DT | awk 'NF>=8 {print \$8 \",\" \$5}' | sed 's#^/data/##' | sort > \"\$INV_DATA\"

if ! hdfs dfs -test -d /backup; then
  echo 'backup_not_found' > \"\$DIFF_TXT\"
  echo 'metric,count' > \"\$SUMMARY_CSV\"
  echo 'backup_missing,1' >> \"\$SUMMARY_CSV\"
  hdfs dfs -put -f \"\$DIFF_TXT\" /audit/inventory/\$DT/inventory_diff.txt
  hdfs dfs -put -f \"\$SUMMARY_CSV\" /audit/inventory/\$DT/inventory_summary.csv
  exit 0
fi

hdfs dfs -ls -R \$DST_DT | awk 'NF>=8 {print \$8 \",\" \$5}' | sed 's#^/backup/##' | sort > \"\$INV_BACKUP\"

awk -F',' '
FNR==NR {b[\$1]=\$2; next}
{
  d[\$1]=\$2
  if (!(\$1 in b)) {missing++; print \"MISSING_BACKUP,\" \$1}
  else if (b[\$1] != \$2) {mismatch++; print \"SIZE_MISMATCH,\" \$1 \",data=\" \$2 \",backup=\" b[\$1]}
}
END {
  for (k in b) if (!(k in d)) {extra++; print \"EXTRA_IN_BACKUP,\" k}
  print \"missing=\" missing+0 \";mismatch=\" mismatch+0 \";extra=\" extra+0 > \"/dev/stderr\"
}
' \"\$INV_BACKUP\" \"\$INV_DATA\" > \"\$DIFF_TXT\" 2> \"\$TMP_DIR/summary.tmp\"

missing=\$(grep -o 'missing=[0-9]*' \"\$TMP_DIR/summary.tmp\" | cut -d= -f2)
mismatch=\$(grep -o 'mismatch=[0-9]*' \"\$TMP_DIR/summary.tmp\" | cut -d= -f2)
extra=\$(grep -o 'extra=[0-9]*' \"\$TMP_DIR/summary.tmp\" | cut -d= -f2)

echo 'metric,count' > \"\$SUMMARY_CSV\"
echo \"missing_in_backup,\${missing:-0}\" >> \"\$SUMMARY_CSV\"
echo \"size_mismatch,\${mismatch:-0}\" >> \"\$SUMMARY_CSV\"
echo \"extra_in_backup,\${extra:-0}\" >> \"\$SUMMARY_CSV\"

hdfs dfs -put -f \"\$INV_DATA\" /audit/inventory/\$DT/inv_data.csv
hdfs dfs -put -f \"\$INV_BACKUP\" /audit/inventory/\$DT/inv_backup.csv
hdfs dfs -put -f \"\$DIFF_TXT\" /audit/inventory/\$DT/inventory_diff.txt
hdfs dfs -put -f \"\$SUMMARY_CSV\" /audit/inventory/\$DT/inventory_summary.csv
"

echo "[inventory] OK"
