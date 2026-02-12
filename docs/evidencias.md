# Evidencias

Ejecuciones documentadas principalmente para `DT=2026-02-04` y validaciones adicionales el `2026-02-05`.

## 1) NameNode UI (9870)
- DataNodes vivos y capacidad total/uso visible en UI.
- Captura:
![NameNode UI](imgs/1.png)

## 2) Auditoria fsck
- Salida de `hdfs fsck /data -files -blocks -locations` (bloques y locations).
- Captura:
![FSCK bloques y locations](imgs/2.png)
- Resumen de conteos (`CORRUPT`, `MISSING`, `UNDER_REPLICATED`) en CSV.
- Captura:
![Resumen FSCK](imgs/2.1.png)
- Evidencia en UI de ficheros de auditoria guardados en `/audit/fsck/2026-02-04/`.
- Captura:
![UI audit fsck](imgs/2.2.png)

Resultado observado: `CORRUPT=0`, `MISSING=0`, `UNDER_REPLICATED=0`.

## 3) Backup + validacion
- Evidencia de copia a `/backup/.../dt=2026-02-04` y listados de rutas/tamanos.
- Capturas:
![Backup y listados](imgs/3.png)
![Backup listado adicional](imgs/3.1.png)
- Resumen de inventario origen vs destino (`inventory_summary.csv`).
- Capturas:
![Resumen inventario](imgs/3.2.png)

Resultado observado:
- `missing_in_backup=0`
- `size_mismatch=0`
- `extra_in_backup=0`

## 4) Incidente + recuperacion
- Simulacion de incidente controlado (parada/arranque de DataNode) y verificacion de estado.
- Capturas:
![Incidente 1](imgs/4.1.png)
![Incidente 2](imgs/4.2.png)
![Incidente 3](imgs/4.3.png)
![Incidente 4](imgs/4.4.png)
![Incidente 5](imgs/4.5.png)
- Recuperacion y validacion final con script de restore.
- Captura:
![Recovery restore](imgs/4.6.png)

## 5) Metricas
- Evidencia de consumo de recursos durante ejecucion (`docker stats`).
- Captura:
![Docker stats](imgs/5.1.png)

Tabla de tiempos/recursos (resumen del notebook `notebooks/03_entrega_integridad_metricas.ipynb`):

| Fase | Duracion (s) | CPU promedio (%) | Memoria promedio (MB) | Nota |
|---|---:|---:|---:|---|
| ingesta_hdfs | 18 | 0.78 | 705.0 | carga inicial en /data |
| fsck_auditoria | 6 | 0.26 | 700.0 | fsck data+backup y resumen |
| backup_copy | 14 | 0.91 | 736.0 | copia /data -> /backup |
| incident_simulation | 33 | 0.42 | 744.0 | parada/arranque de DataNode |
| recovery_restore | 20 | 0.58 | 766.0 | restauracion y verificacion final |
