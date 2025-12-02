#!/bin/bash
# Script para hacer backup de los volúmenes de FreePBX
# Uso: ./backup.sh

set -e

BACKUP_DIR="./backups"
COMPOSE_PROJECT="freepbx-zoiper"

echo "🔄 Creando directorio de backups..."
mkdir -p $BACKUP_DIR

echo "⏸️  Deteniendo contenedor..."
docker-compose down

echo "📦 Exportando volúmenes..."

docker run --rm -v ${COMPOSE_PROJECT}_freepbx_data:/data -v $(pwd)/$BACKUP_DIR:/backup alpine tar czf /backup/freepbx_data.tar.gz -C /data .
echo "✅ freepbx_data exportado"

docker run --rm -v ${COMPOSE_PROJECT}_freepbx_db:/data -v $(pwd)/$BACKUP_DIR:/backup alpine tar czf /backup/freepbx_db.tar.gz -C /data .
echo "✅ freepbx_db exportado"

docker run --rm -v ${COMPOSE_PROJECT}_freepbx_www:/data -v $(pwd)/$BACKUP_DIR:/backup alpine tar czf /backup/freepbx_www.tar.gz -C /data .
echo "✅ freepbx_www exportado"

docker run --rm -v ${COMPOSE_PROJECT}_freepbx_logs:/data -v $(pwd)/$BACKUP_DIR:/backup alpine tar czf /backup/freepbx_logs.tar.gz -C /data .
echo "✅ freepbx_logs exportado"

echo "▶️  Reiniciando contenedor..."
docker-compose up -d

echo ""
echo "🎉 Backup completado! Archivos en: $BACKUP_DIR/"
ls -lh $BACKUP_DIR/

