#!/bin/bash

# Directorio del proyecto
cd /home/bumblebee/asterik_freepbx

# Log file
LOG_FILE="/home/bumblebee/asterik_freepbx/trunk_monitor.log"

# Función para registrar en log
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Función para verificar estado de un trunk específico
check_trunk_status() {
    local trunk_name=$1
    local status_output=$2
    
    # Buscar el endpoint y verificar si está Avail o Unavail
    if echo "$status_output" | grep -A 2 "Endpoint:.*$trunk_name" | grep -q "Avail"; then
        return 0  # Trunk disponible
    else
        return 1  # Trunk no disponible
    fi
}

log "=== Iniciando monitoreo de trunks ==="

# Lista de trunks críticos a monitorear
TRUNKS=(
    "pillardhld"
    "ElevenLabs_1631"
    "ElevenLabs_8039"
    "ElevenLabs_9173"
    "ElevenLabs_1622"
    "ElevenLabs_1697"
    "ElevenLabs_1709"
    "ElevenLabs"
    "1001"
)

# Obtener estado de los trunks
STATUS_OUTPUT=$(docker exec freepbx asterisk -rx "pjsip show endpoints" 2>&1)

# Array para almacenar trunks problemáticos
UNAVAILABLE_TRUNKS=()

# Verificar cada trunk
for trunk in "${TRUNKS[@]}"; do
    if ! check_trunk_status "$trunk" "$STATUS_OUTPUT"; then
        UNAVAILABLE_TRUNKS+=("$trunk")
        log "⚠️  Trunk $trunk está UNAVAILABLE o sin contacto"
    fi
done

# Si hay trunks no disponibles, tomar acciones
if [ ${#UNAVAILABLE_TRUNKS[@]} -gt 0 ]; then
    log "⚠️  Total de trunks con problemas: ${#UNAVAILABLE_TRUNKS[@]}"
    log "   Trunks afectados: ${UNAVAILABLE_TRUNKS[*]}"
    
    # Si pillardhld está caído, ejecutar make network
    if [[ " ${UNAVAILABLE_TRUNKS[*]} " =~ " pillardhld " ]]; then
        log "🔧 Trunk pillardhld (Altice) caído - Ejecutando 'make network'..."
        NETWORK_OUTPUT=$(sudo make network 2>&1)
        log "Resultado make network: $NETWORK_OUTPUT"
        sleep 5
    fi
    
    # Ejecutar qualify para todos los trunks
    log "🔄 Ejecutando 'make qualify' para refrescar todos los trunks..."
    QUALIFY_OUTPUT=$(make qualify 2>&1)
    
    # Verificar estado después del qualify
    sleep 3
    STATUS_OUTPUT_AFTER=$(docker exec freepbx asterisk -rx "pjsip show endpoints" 2>&1)
    
    STILL_DOWN=()
    for trunk in "${UNAVAILABLE_TRUNKS[@]}"; do
        if ! check_trunk_status "$trunk" "$STATUS_OUTPUT_AFTER"; then
            STILL_DOWN+=("$trunk")
        else
            log "✅ Trunk $trunk recuperado"
        fi
    done
    
    if [ ${#STILL_DOWN[@]} -gt 0 ]; then
        log "❌ Trunks que siguen caídos después de qualify: ${STILL_DOWN[*]}"
    else
        log "✅ Todos los trunks recuperados exitosamente"
    fi
else
    log "✅ Todos los trunks están disponibles (Avail)"
fi

log "=== Monitoreo completado ==="
