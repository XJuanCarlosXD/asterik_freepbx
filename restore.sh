#!/bin/bash
# Script para restaurar los volúmenes de FreePBX
# Uso: ./restore.sh

set -e

BACKUP_DIR="./backups"
COMPOSE_PROJECT="freepbx-zoiper"

echo "🔍 Verificando backups..."
if [ ! -d "$BACKUP_DIR" ]; then
    echo "❌ Error: No se encontró el directorio $BACKUP_DIR"
    exit 1
fi

echo "📦 Creando volúmenes..."
docker volume create ${COMPOSE_PROJECT}_freepbx_data || true
docker volume create ${COMPOSE_PROJECT}_freepbx_db || true
docker volume create ${COMPOSE_PROJECT}_freepbx_www || true
docker volume create ${COMPOSE_PROJECT}_freepbx_logs || true

echo "🔄 Restaurando volúmenes..."

if [ -f "$BACKUP_DIR/freepbx_data.tar.gz" ]; then
    docker run --rm -v ${COMPOSE_PROJECT}_freepbx_data:/data -v $(pwd)/$BACKUP_DIR:/backup alpine tar xzf /backup/freepbx_data.tar.gz -C /data
    echo "✅ freepbx_data restaurado"
fi

if [ -f "$BACKUP_DIR/freepbx_db.tar.gz" ]; then
    docker run --rm -v ${COMPOSE_PROJECT}_freepbx_db:/data -v $(pwd)/$BACKUP_DIR:/backup alpine tar xzf /backup/freepbx_db.tar.gz -C /data
    echo "✅ freepbx_db restaurado"
fi

if [ -f "$BACKUP_DIR/freepbx_www.tar.gz" ]; then
    docker run --rm -v ${COMPOSE_PROJECT}_freepbx_www:/data -v $(pwd)/$BACKUP_DIR:/backup alpine tar xzf /backup/freepbx_www.tar.gz -C /data
    echo "✅ freepbx_www restaurado"
fi

if [ -f "$BACKUP_DIR/freepbx_logs.tar.gz" ]; then
    docker run --rm -v ${COMPOSE_PROJECT}_freepbx_logs:/data -v $(pwd)/$BACKUP_DIR:/backup alpine tar xzf /backup/freepbx_logs.tar.gz -C /data
    echo "✅ freepbx_logs restaurado"
fi

echo "▶️  Iniciando FreePBX..."
docker-compose up -d

echo ""
echo "🎉 Restauración completada!"
echo "⏳ Espera ~2 minutos y accede a http://localhost/admin"

