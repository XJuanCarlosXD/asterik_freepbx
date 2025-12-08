# =====================================================
# Makefile para FreePBX + ElevenLabs + Altice
# Uso: make <comando>
# =====================================================

.PHONY: status endpoints registrations transports logs qualify network backup restore help install up down

# Variables
COMPOSE_PROJECT = freepbx-zoiper
BACKUP_DIR = ./backups
USB_INTERFACE = enx000ec675c192
CLIENT_IP = 172.17.206.182
NETMASK = /30
GATEWAY = 172.17.206.181
ALTICE_SIGNALING = 186.150.82.2
ALTICE_MEDIA = 186.150.82.34

# =====================================================
# ESTADO
# =====================================================

# Mostrar estado de todos los trunks
status:
	@echo "📊 === ESTADO DE TRUNKS ==="
	@docker exec freepbx asterisk -rx "pjsip show endpoints"

# Mostrar endpoints detallado
endpoints:
	@echo "📡 === ENDPOINTS ==="
	@docker exec freepbx asterisk -rx "pjsip show endpoints"

# Mostrar registraciones
registrations:
	@echo "📝 === REGISTRACIONES ==="
	@docker exec freepbx asterisk -rx "pjsip show registrations"

# Mostrar transportes
transports:
	@echo "🚀 === TRANSPORTES ==="
	@docker exec freepbx asterisk -rx "pjsip show transports"

# Forzar qualify de todos los trunks
qualify:
	@echo "🔄 === QUALIFY TRUNKS ==="
	@docker exec freepbx asterisk -rx "pjsip qualify 1001"
	@docker exec freepbx asterisk -rx "pjsip qualify ElevenLabs"
	@docker exec freepbx asterisk -rx "pjsip qualify pillardhld"
	@sleep 3
	@$(MAKE) status

# Estado completo del sistema
full-status:
	@echo "📊 === ESTADO COMPLETO DEL SISTEMA ==="
	@echo ""
	@echo "🚀 TRANSPORTES:"
	@docker exec freepbx asterisk -rx "pjsip show transports"
	@echo ""
	@echo "📡 ENDPOINTS:"
	@docker exec freepbx asterisk -rx "pjsip show endpoints"
	@echo ""
	@echo "📝 REGISTRACIONES:"
	@docker exec freepbx asterisk -rx "pjsip show registrations"

# =====================================================
# RED
# =====================================================

# Configurar red para Altice (requiere sudo)
network:
	@echo "🔧 === CONFIGURANDO RED ALTICE ==="
	@if ! ip link show $(USB_INTERFACE) &>/dev/null; then \
		echo "❌ Error: Interfaz USB $(USB_INTERFACE) no encontrada"; \
		echo "   Verifica que el adaptador USB esté conectado"; \
		exit 1; \
	fi
	@echo "📡 Asignando IP $(CLIENT_IP)$(NETMASK) a $(USB_INTERFACE)..."
	@sudo ip addr flush dev $(USB_INTERFACE) 2>/dev/null || true
	@sudo ip addr add $(CLIENT_IP)$(NETMASK) dev $(USB_INTERFACE)
	@sudo ip link set $(USB_INTERFACE) up
	@echo "🛤️  Agregando rutas hacia Altice..."
	@sudo ip route del $(ALTICE_SIGNALING)/32 2>/dev/null || true
	@sudo ip route del $(ALTICE_MEDIA)/32 2>/dev/null || true
	@sudo ip route add $(ALTICE_SIGNALING)/32 via $(GATEWAY) dev $(USB_INTERFACE)
	@sudo ip route add $(ALTICE_MEDIA)/32 via $(GATEWAY) dev $(USB_INTERFACE)
	@echo "🔍 Verificando conectividad..."
	@ping -c 1 -W 2 $(ALTICE_SIGNALING) && echo "✅ Altice Signaling OK" || echo "⚠️  Sin respuesta de Altice Signaling"
	@ping -c 1 -W 2 $(ALTICE_MEDIA) && echo "✅ Altice Media OK" || echo "⚠️  Sin respuesta de Altice Media"
	@echo ""
	@echo "📋 Configuración actual:"
	@ip addr show $(USB_INTERFACE) | grep inet || true
	@echo ""
	@echo "🛤️  Rutas hacia Altice:"
	@ip route | grep -E "$(ALTICE_SIGNALING)|$(ALTICE_MEDIA)" || true
	@echo ""
	@echo "🎉 Configuración de red completada!"

# Ver IP de interfaz USB (Altice)
usb-ip:
	@echo "🔌 === INTERFAZ USB (ALTICE) ==="
	@ip addr show $(USB_INTERFACE) 2>/dev/null || echo "❌ Interfaz USB no encontrada"
	@echo ""
	@echo "🛤️  RUTAS HACIA ALTICE:"
	@ip route | grep -E "186.150.82|172.17.206" || echo "❌ No hay rutas hacia Altice"

# Ver todas las IPs del sistema/docker
ips:
	@echo "🌐 === IPs DEL SISTEMA ==="
	@echo ""
	@echo "📡 INTERFACES ACTIVAS:"
	@ip -4 addr show | grep -E "inet |^[0-9]" | grep -v "127.0.0.1"
	@echo ""
	@echo "🐳 IPs VISIBLES EN DOCKER:"
	@docker exec freepbx ip -4 addr show | grep -E "inet |^[0-9]" | grep -v "127.0.0.1"

# Ver solo interfaces principales
interfaces:
	@echo "🔗 === INTERFACES DE RED ==="
	@echo ""
	@echo "📌 enp4s0 (Principal):"
	@ip addr show enp4s0 | grep "inet "
	@echo ""
	@echo "🔌 $(USB_INTERFACE) (USB/Altice):"
	@ip addr show $(USB_INTERFACE) 2>/dev/null | grep "inet " || echo "   ❌ Sin IP asignada"
	@echo ""
	@echo "🐳 Docker (freepbx):"
	@docker exec freepbx hostname -I

# Ping a Altice
ping-altice:
	@echo "🏓 === PING A ALTICE ==="
	@echo "Signaling ($(ALTICE_SIGNALING)):"
	@ping -c 2 $(ALTICE_SIGNALING) || echo "❌ Sin conexión"
	@echo ""
	@echo "Media ($(ALTICE_MEDIA)):"
	@ping -c 2 $(ALTICE_MEDIA) || echo "❌ Sin conexión"

# Ping a ElevenLabs
ping-elevenlabs:
	@echo "🏓 === PING A ELEVENLABS ==="
	@ping -c 2 sip.rtc.elevenlabs.io || echo "❌ Sin conexión"

# =====================================================
# LOGS
# =====================================================

# Ver logs en tiempo real
logs:
	@echo "📋 === LOGS EN TIEMPO REAL (Ctrl+C para salir) ==="
	@docker exec freepbx tail -f /var/log/asterisk/full

# Ver últimos 50 logs
logs-tail:
	@echo "📋 === ÚLTIMOS 50 LOGS ==="
	@docker exec freepbx tail -50 /var/log/asterisk/full

# Habilitar logs SIP
sip-debug:
	@echo "🐛 === HABILITANDO DEBUG SIP ==="
	@docker exec freepbx asterisk -rx "pjsip set logger on"
	@echo "Debug SIP habilitado. Usa 'make logs' para ver."

# Deshabilitar logs SIP
sip-debug-off:
	@echo "🔇 === DESHABILITANDO DEBUG SIP ==="
	@docker exec freepbx asterisk -rx "pjsip set logger off"

# =====================================================
# CONTROL
# =====================================================

# Reiniciar Asterisk
restart:
	@echo "🔄 === REINICIANDO ASTERISK ==="
	@docker exec freepbx asterisk -rx "core restart now"
	@sleep 10
	@$(MAKE) qualify

# Recargar dialplan
reload:
	@echo "🔄 === RECARGANDO DIALPLAN ==="
	@docker exec freepbx asterisk -rx "dialplan reload"
	@docker exec freepbx asterisk -rx "module reload res_pjsip.so"

# Ver dialplan de ElevenLabs
dialplan:
	@echo "📞 === DIALPLAN ELEVENLABS ==="
	@docker exec freepbx asterisk -rx "dialplan show to-elevenlabs-bot"

# =====================================================
# BACKUP Y RESTORE
# =====================================================

# Ejecutar backup
backup:
	@echo "💾 === EJECUTANDO BACKUP ==="
	@echo "🔄 Creando directorio de backups..."
	@mkdir -p $(BACKUP_DIR)
	@echo "⏸️  Deteniendo contenedor..."
	@docker compose down
	@echo "📦 Exportando volúmenes..."
	@docker run --rm -v $(COMPOSE_PROJECT)_freepbx_data:/data -v $(shell pwd)/$(BACKUP_DIR):/backup alpine tar czf /backup/freepbx_data.tar.gz -C /data .
	@echo "✅ freepbx_data exportado"
	@docker run --rm -v $(COMPOSE_PROJECT)_freepbx_db:/data -v $(shell pwd)/$(BACKUP_DIR):/backup alpine tar czf /backup/freepbx_db.tar.gz -C /data .
	@echo "✅ freepbx_db exportado"
	@docker run --rm -v $(COMPOSE_PROJECT)_freepbx_www:/data -v $(shell pwd)/$(BACKUP_DIR):/backup alpine tar czf /backup/freepbx_www.tar.gz -C /data .
	@echo "✅ freepbx_www exportado"
	@docker run --rm -v $(COMPOSE_PROJECT)_freepbx_logs:/data -v $(shell pwd)/$(BACKUP_DIR):/backup alpine tar czf /backup/freepbx_logs.tar.gz -C /data .
	@echo "✅ freepbx_logs exportado"
	@echo "▶️  Reiniciando contenedor..."
	@docker compose up -d
	@echo ""
	@echo "🎉 Backup completado! Archivos en: $(BACKUP_DIR)/"
	@ls -lh $(BACKUP_DIR)/

# Restaurar backup
restore:
	@echo "♻️ === RESTAURANDO BACKUP ==="
	@echo "🔍 Verificando backups..."
	@if [ ! -d "$(BACKUP_DIR)" ]; then \
		echo "❌ Error: No se encontró el directorio $(BACKUP_DIR)"; \
		exit 1; \
	fi
	@echo "📦 Creando volúmenes..."
	@docker volume create $(COMPOSE_PROJECT)_freepbx_data || true
	@docker volume create $(COMPOSE_PROJECT)_freepbx_db || true
	@docker volume create $(COMPOSE_PROJECT)_freepbx_www || true
	@docker volume create $(COMPOSE_PROJECT)_freepbx_logs || true
	@echo "🔄 Restaurando volúmenes..."
	@if [ -f "$(BACKUP_DIR)/freepbx_data.tar.gz" ]; then \
		docker run --rm -v $(COMPOSE_PROJECT)_freepbx_data:/data -v $(shell pwd)/$(BACKUP_DIR):/backup alpine tar xzf /backup/freepbx_data.tar.gz -C /data; \
		echo "✅ freepbx_data restaurado"; \
	fi
	@if [ -f "$(BACKUP_DIR)/freepbx_db.tar.gz" ]; then \
		docker run --rm -v $(COMPOSE_PROJECT)_freepbx_db:/data -v $(shell pwd)/$(BACKUP_DIR):/backup alpine tar xzf /backup/freepbx_db.tar.gz -C /data; \
		echo "✅ freepbx_db restaurado"; \
	fi
	@if [ -f "$(BACKUP_DIR)/freepbx_www.tar.gz" ]; then \
		docker run --rm -v $(COMPOSE_PROJECT)_freepbx_www:/data -v $(shell pwd)/$(BACKUP_DIR):/backup alpine tar xzf /backup/freepbx_www.tar.gz -C /data; \
		echo "✅ freepbx_www restaurado"; \
	fi
	@if [ -f "$(BACKUP_DIR)/freepbx_logs.tar.gz" ]; then \
		docker run --rm -v $(COMPOSE_PROJECT)_freepbx_logs:/data -v $(shell pwd)/$(BACKUP_DIR):/backup alpine tar xzf /backup/freepbx_logs.tar.gz -C /data; \
		echo "✅ freepbx_logs restaurado"; \
	fi
	@echo "▶️  Iniciando FreePBX..."
	@docker compose up -d
	@echo ""
	@echo "🎉 Restauración completada!"
	@echo "⏳ Espera ~2 minutos y accede a http://localhost/admin"

# =====================================================
# DOCKER
# =====================================================

# Iniciar contenedor
up:
	@echo "▶️  === INICIANDO FREEPBX ==="
	@docker compose up -d
	@echo "⏳ Esperando que FreePBX inicie..."
	@sleep 10
	@echo "✅ FreePBX iniciado"

# Detener contenedor
down:
	@echo "⏹️  === DETENIENDO FREEPBX ==="
	@docker compose down
	@echo "✅ FreePBX detenido"

# =====================================================
# INSTALACIÓN
# =====================================================

# Instalación completa del proyecto
install:
	@echo "╔════════════════════════════════════════════════════════════╗"
	@echo "║     🚀 INSTALACIÓN DE FREEPBX + ELEVENLABS + ALTICE        ║"
	@echo "╚════════════════════════════════════════════════════════════╝"
	@echo ""
	@# Paso 1: Verificar Docker
	@echo "📋 Paso 1: Verificando Docker..."
	@if ! command -v docker &>/dev/null; then \
		echo "❌ Error: Docker no está instalado"; \
		exit 1; \
	fi
	@echo "✅ Docker disponible"
	@echo ""
	@# Paso 2: Configurar red USB si existe
	@echo "📋 Paso 2: Configurando red..."
	@if ip link show $(USB_INTERFACE) &>/dev/null; then \
		echo "🔌 Interfaz USB $(USB_INTERFACE) detectada"; \
		echo "📡 Configurando IP $(CLIENT_IP)$(NETMASK)..."; \
		sudo ip addr flush dev $(USB_INTERFACE) 2>/dev/null || true; \
		sudo ip addr add $(CLIENT_IP)$(NETMASK) dev $(USB_INTERFACE); \
		sudo ip link set $(USB_INTERFACE) up; \
		sudo ip route del $(ALTICE_SIGNALING)/32 2>/dev/null || true; \
		sudo ip route del $(ALTICE_MEDIA)/32 2>/dev/null || true; \
		sudo ip route add $(ALTICE_SIGNALING)/32 via $(GATEWAY) dev $(USB_INTERFACE); \
		sudo ip route add $(ALTICE_MEDIA)/32 via $(GATEWAY) dev $(USB_INTERFACE); \
		echo "✅ Red Altice configurada"; \
	else \
		echo "⚠️  Interfaz USB $(USB_INTERFACE) no encontrada (saltando config Altice)"; \
	fi
	@echo ""
	@# Paso 3: Verificar si hay backup y preguntar
	@echo "📋 Paso 3: Verificando backups..."
	@if [ -d "$(BACKUP_DIR)" ] && [ -f "$(BACKUP_DIR)/freepbx_data.tar.gz" ]; then \
		echo "📦 Backup encontrado en $(BACKUP_DIR)/"; \
		echo ""; \
		read -p "¿Deseas restaurar el backup? [s/N]: " respuesta; \
		if [ "$$respuesta" = "s" ] || [ "$$respuesta" = "S" ]; then \
			echo "♻️  Restaurando backup..."; \
			docker volume create $(COMPOSE_PROJECT)_freepbx_data 2>/dev/null || true; \
			docker volume create $(COMPOSE_PROJECT)_freepbx_db 2>/dev/null || true; \
			docker volume create $(COMPOSE_PROJECT)_freepbx_www 2>/dev/null || true; \
			docker volume create $(COMPOSE_PROJECT)_freepbx_logs 2>/dev/null || true; \
			docker run --rm -v $(COMPOSE_PROJECT)_freepbx_data:/data -v $(shell pwd)/$(BACKUP_DIR):/backup alpine tar xzf /backup/freepbx_data.tar.gz -C /data; \
			docker run --rm -v $(COMPOSE_PROJECT)_freepbx_db:/data -v $(shell pwd)/$(BACKUP_DIR):/backup alpine tar xzf /backup/freepbx_db.tar.gz -C /data; \
			docker run --rm -v $(COMPOSE_PROJECT)_freepbx_www:/data -v $(shell pwd)/$(BACKUP_DIR):/backup alpine tar xzf /backup/freepbx_www.tar.gz -C /data; \
			docker run --rm -v $(COMPOSE_PROJECT)_freepbx_logs:/data -v $(shell pwd)/$(BACKUP_DIR):/backup alpine tar xzf /backup/freepbx_logs.tar.gz -C /data; \
			echo "✅ Backup restaurado"; \
		else \
			echo "⏭️  Saltando restauración de backup"; \
		fi; \
	else \
		echo "📭 No se encontró backup (instalación limpia)"; \
	fi
	@echo ""
	@# Paso 4: Iniciar contenedor
	@echo "📋 Paso 4: Iniciando FreePBX..."
	@docker compose up -d
	@echo "⏳ Esperando que FreePBX inicie (60 segundos)..."
	@sleep 60
	@echo "✅ FreePBX iniciado"
	@echo ""
	@# Paso 5: Qualify trunks
	@echo "📋 Paso 5: Verificando trunks..."
	@docker exec freepbx asterisk -rx "pjsip qualify 1001" 2>/dev/null || true
	@docker exec freepbx asterisk -rx "pjsip qualify ElevenLabs" 2>/dev/null || true
	@docker exec freepbx asterisk -rx "pjsip qualify pillardhld" 2>/dev/null || true
	@sleep 5
	@echo ""
	@# Paso 6: Mostrar status
	@echo "📋 Paso 6: Estado del sistema..."
	@echo ""
	@docker exec freepbx asterisk -rx "pjsip show endpoints"
	@echo ""
	@echo "╔════════════════════════════════════════════════════════════╗"
	@echo "║     🎉 INSTALACIÓN COMPLETADA                              ║"
	@echo "╠════════════════════════════════════════════════════════════╣"
	@echo "║  Accede a FreePBX: http://localhost/admin                  ║"
	@echo "║  Usa 'make help' para ver todos los comandos               ║"
	@echo "╚════════════════════════════════════════════════════════════╝"

# =====================================================
# AYUDA
# =====================================================

help:
	@echo "╔════════════════════════════════════════════════════════════╗"
	@echo "║      FreePBX + ElevenLabs + Altice - Comandos              ║"
	@echo "╠════════════════════════════════════════════════════════════╣"
	@echo "║  INSTALACIÓN:                                              ║"
	@echo "║    make install       - Instalación completa (interactivo) ║"
	@echo "║    make up            - Iniciar contenedor                 ║"
	@echo "║    make down          - Detener contenedor                 ║"
	@echo "╠════════════════════════════════════════════════════════════╣"
	@echo "║  ESTADO:                                                   ║"
	@echo "║    make status        - Estado de trunks                   ║"
	@echo "║    make qualify       - Forzar qualify de trunks           ║"
	@echo "║    make full-status   - Estado completo del sistema        ║"
	@echo "║    make transports    - Ver transportes                    ║"
	@echo "║    make registrations - Ver registraciones                 ║"
	@echo "╠════════════════════════════════════════════════════════════╣"
	@echo "║  RED:                                                      ║"
	@echo "║    make network       - Configurar red Altice (sudo)       ║"
	@echo "║    make usb-ip        - Ver IP interfaz USB (Altice)       ║"
	@echo "║    make ips           - Ver todas las IPs del sistema      ║"
	@echo "║    make interfaces    - Ver interfaces principales         ║"
	@echo "║    make ping-altice   - Ping a Altice                      ║"
	@echo "║    make ping-elevenlabs - Ping a ElevenLabs                ║"
	@echo "╠════════════════════════════════════════════════════════════╣"
	@echo "║  LOGS:                                                     ║"
	@echo "║    make logs          - Ver logs en tiempo real            ║"
	@echo "║    make logs-tail     - Ver últimos 50 logs                ║"
	@echo "║    make sip-debug     - Habilitar debug SIP                ║"
	@echo "║    make sip-debug-off - Deshabilitar debug SIP             ║"
	@echo "╠════════════════════════════════════════════════════════════╣"
	@echo "║  CONTROL:                                                  ║"
	@echo "║    make restart       - Reiniciar Asterisk                 ║"
	@echo "║    make reload        - Recargar dialplan                  ║"
	@echo "║    make dialplan      - Ver dialplan ElevenLabs            ║"
	@echo "║    make backup        - Ejecutar backup                    ║"
	@echo "║    make restore       - Restaurar backup                   ║"
	@echo "╚════════════════════════════════════════════════════════════╝"
