# DataSecure Lab — Integridad de Datos en Big Data (HDFS)

Repositorio base del proyecto práctico **Integridad de Datos en Big Data** usando un ecosistema **Hadoop dockerizado** del aula.

-  Enunciado: `docs/enunciado_proyecto.md`
-  Rúbrica: `docs/rubric.md`
-  Pistas rápidas: `docs/pistas.md`
-  Entrega (individual): `docs/entrega.md`
-  Plantilla de evidencias: `docs/evidencias.md`

---

## Quickstart (para corrección)

```bash
cd docker/clusterA && docker compose up -d
bash scripts/00_bootstrap.sh && bash scripts/10_generate_data.sh && bash scripts/20_ingest_hdfs.sh
bash scripts/30_fsck_audit.sh && bash scripts/40_backup_copy.sh && bash scripts/50_inventory_compare.sh
bash scripts/70_incident_simulation.sh && bash scripts/80_recovery_restore.sh
```

> Si algún script necesita variables:  
> `DT=YYYY-MM-DD` (fecha) y `NN_CONTAINER=namenode` (nombre del contenedor NameNode).

---

## Servicios y UIs
- NameNode UI: http://localhost:9870
- ResourceManager UI: http://localhost:8088
- Jupyter (NameNode): http://localhost:8889

---

## Parametros HDFS (R2)

### Ubicacion de XML de configuracion
- Ruta de configuracion usada en el despliegue: `/opt/hadoop/etc/hadoop/`.
- Ficheros relevantes en esa ruta: `/opt/hadoop/etc/hadoop/core-site.xml`, `/opt/hadoop/etc/hadoop/hdfs-site.xml`, `/opt/hadoop/etc/hadoop/yarn-site.xml`, `/opt/hadoop/etc/hadoop/mapred-site.xml`.
- Ruta alternativa habitual (segun imagen): `/etc/hadoop/`.

### Valores usados en la practica
- `dfs.blocksize = 67108864` bytes (64 MB).
- `dfs.replication = 3`.
- Comandos de comprobacion:
  - `docker exec -it namenode bash -lc "hdfs getconf -confKey dfs.blocksize"`
  - `docker exec -it namenode bash -lc "hdfs getconf -confKey dfs.replication"`

### Justificacion (integridad vs coste)
Con `dfs.blocksize=64 MB` se mantiene un equilibrio razonable entre metadatos y paralelismo para ficheros grandes de logs/IoT.  
Bloques mas pequenos mejoran granularidad, pero aumentan la carga de metadatos en NameNode y el overhead de gestion.  
Bloques mas grandes reducen metadatos, pero pueden penalizar paralelismo y tiempos de recuperacion de bloques concretos.  
Con `dfs.replication=3` se tolera la caida de un DataNode sin perder disponibilidad ni comprometer lectura.  
Replicacion `1` reduce coste de disco/red, pero sube mucho el riesgo de perdida ante fallo de nodo.  
Replicacion `2` mejora respecto a `1`, aunque sigue con menor margen de seguridad que `3` para incidentes simultaneos.  
Replicacion `3` incrementa coste de almacenamiento y escritura, pero es un estandar practico para datos con criticidad media/alta.  
HDFS valida integridad con checksums CRC por bloque durante lectura/escritura y deteccion de corrupcion.  
SHA/MD5 no sustituyen ese mecanismo interno: se usan como verificacion adicional a nivel aplicacion (end-to-end) para contrastar origen y destino.  
En este laboratorio, los resultados de `fsck` e inventario con `replication=3` muestran consistencia y recuperacion estable tras incidente.  
Por coste/beneficio, se recomienda mantener `3` en produccion de referencia y ajustar segun criticidad y presupuesto.

---

## Estructura del repositorio
- `docker/clusterA/`: docker-compose del aula (Cluster A)
- `scripts/`: pipeline (generación → ingesta → auditoría → backup → incidente → recuperación)
- `notebooks/`: análisis en Jupyter (tabla de auditorías y métricas)
- `docs/`: documentación (enunciado, rúbrica, pistas, entrega, evidencias)

---

## Normas de entrega (individual)
Consulta `docs/entrega.md`.  
**Obligatorio:** tag final `v1.0-entrega`.

---

## Nota
Este repositorio es un “starter kit”: algunos scripts contienen **TODOs** para completar el proyecto.
