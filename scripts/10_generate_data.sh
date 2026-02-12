#!/usr/bin/env bash
set -euo pipefail

# Genera dataset realista (logs e IoT) con tamaño suficiente.
# Recomendación: 1–2GB totales para observar bloques.

OUT_DIR=${OUT_DIR:-./data_local}
DT=${DT:-$(date +%F)}
LOGS_MB=${LOGS_MB:-512}
IOT_MB=${IOT_MB:-512}

mkdir -p "$OUT_DIR/$DT"

echo "[generate] DT=$DT"
echo "[generate] Salida: $OUT_DIR/$DT"
echo "[generate] Tamaño objetivo: logs=${LOGS_MB}MB iot=${IOT_MB}MB"

export DT OUT_DIR LOGS_MB IOT_MB
python3 - <<'PY'
import os, json, random, time

dt = os.environ["DT"]
out_dir = os.environ["OUT_DIR"]
logs_mb = int(os.environ.get("LOGS_MB", "512"))
iot_mb = int(os.environ.get("IOT_MB", "512"))

dt_compact = dt.replace("-", "")
log_path = os.path.join(out_dir, dt, f"logs_{dt_compact}.log")
iot_path = os.path.join(out_dir, dt, f"iot_{dt_compact}.jsonl")

random.seed(42)

def write_logs(path, target_mb):
    target = target_mb * 1024 * 1024
    actions = ["login", "logout", "search", "purchase", "download", "upload"]
    statuses = ["200", "201", "204", "400", "401", "403", "404", "500"]
    ips = ["10.0.0.%d" % i for i in range(1, 255)]
    start = time.time()
    with open(path, "w", encoding="utf-8") as f:
        while f.tell() < target:
            lines = []
            for _ in range(10000):
                ts = time.strftime("%Y-%m-%dT%H:%M:%S", time.gmtime(start + random.randint(0, 86400)))
                user_id = random.randint(1, 500000)
                action = random.choice(actions)
                status = random.choice(statuses)
                latency = random.randint(5, 2000)
                ip = random.choice(ips)
                line = f"{ts} user=u{user_id} action={action} status={status} latency={latency}ms ip={ip}\n"
                lines.append(line)
            f.write("".join(lines))

def write_iot(path, target_mb):
    target = target_mb * 1024 * 1024
    metrics = ["temp", "humidity", "pressure", "vibration", "co2"]
    start = time.time()
    with open(path, "w", encoding="utf-8") as f:
        while f.tell() < target:
            lines = []
            for _ in range(10000):
                payload = {
                    "deviceId": f"dev-{random.randint(1, 200000)}",
                    "ts": time.strftime("%Y-%m-%dT%H:%M:%S", time.gmtime(start + random.randint(0, 86400))),
                    "metric": random.choice(metrics),
                    "value": round(random.uniform(0, 100), 3),
                }
                lines.append(json.dumps(payload) + "\n")
            f.write("".join(lines))

write_logs(log_path, logs_mb)
write_iot(iot_path, iot_mb)

print(f"[generate] OK logs={os.path.getsize(log_path)} bytes iot={os.path.getsize(iot_path)} bytes")
PY
