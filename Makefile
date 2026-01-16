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
	@docker exec freepbx asterisk -rx "pjsip qualify ElevenLabs_1631"
	@docker exec freepbx asterisk -rx "pjsip qualify ElevenLabs_8039"
	@docker exec freepbx asterisk -rx "pjsip qualify ElevenLabs_9173"
	@docker exec freepbx asterisk -rx "pjsip qualify ElevenLabs_1622"
	@docker exec freepbx asterisk -rx "pjsip qualify ElevenLabs_1697"
	@docker exec freepbx asterisk -rx "pjsip qualify ElevenLabs_1709"
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
	@if ! ip link show $(USB_INTERFACE) 2>/dev/null | grep -q $(USB_INTERFACE); then \
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

# Configurar NAT/IP externa automáticamente
configure-nat:
	@echo "🔧 === CONFIGURANDO NAT/IP EXTERNA ==="
	@EXTERNAL_IP=$$(curl -s http://ifconfig.me 2>/dev/null || echo ""); \
	if [ -z "$$EXTERNAL_IP" ]; then \
		echo "❌ Error: No se pudo obtener la IP externa"; \
		exit 1; \
	fi; \
	echo "📡 IP Externa detectada: $$EXTERNAL_IP"; \
	echo "📝 Configurando archivos..."; \
	docker exec freepbx sh -c "cat > /etc/asterisk/rtp_custom.conf << EOF\n\
; Configuración de IP externa para RTP\n\
; Configurado automáticamente - NO EDITAR MANUALMENTE\n\
externip=$$EXTERNAL_IP\n\
localnet=192.168.0.0/255.255.0.0\n\
localnet=10.0.0.0/255.0.0.0\n\
localnet=172.16.0.0/255.240.0.0\n\
localnet=127.0.0.1/255.255.255.255\n\
nat=yes\n\
EOF"; \
	docker exec freepbx sh -c "cat > /etc/asterisk/sip_general_custom.conf << EOF\n\
; Configuración NAT para SIP\n\
; Configurado automáticamente - NO EDITAR MANUALMENTE\n\
externip=$$EXTERNAL_IP\n\
localnet=192.168.0.0/255.255.0.0\n\
localnet=10.0.0.0/255.0.0.0\n\
localnet=172.16.0.0/255.240.0.0\n\
localnet=127.0.0.1/255.255.255.255\n\
nat=force_rport,comedia\n\
EOF"; \
	docker exec freepbx sh -c "cat > /etc/asterisk/pjsip_custom_post.conf << EOF\n\
; Configuración de IP externa para RTP/NAT\n\
; Configurado automáticamente - NO EDITAR MANUALMENTE\n\
[global]\n\
external_media_address=$$EXTERNAL_IP\n\
external_signaling_address=$$EXTERNAL_IP\n\
EOF"; \
	echo "🔄 Recargando módulos..."; \
	docker exec freepbx asterisk -rx "module reload res_rtp_asterisk.so" >/dev/null 2>&1; \
	docker exec freepbx asterisk -rx "module reload res_pjsip.so" >/dev/null 2>&1; \
	docker exec freepbx asterisk -rx "dialplan reload" >/dev/null 2>&1; \
	echo "✅ Configuración de NAT completada"; \
	echo "⚠️  NOTA: Si el problema persiste, configura la IP externa desde FreePBX:"; \
	echo "   Settings → Asterisk SIP Settings → External IP: $$EXTERNAL_IP"

# Verificar configuración NAT
check-nat:
	@echo "🔍 === VERIFICANDO CONFIGURACIÓN NAT ==="
	@echo ""
	@echo "📡 IP Externa (detectada):"
	@curl -s http://ifconfig.me 2>/dev/null || echo "❌ No se pudo obtener"
	@echo ""
	@echo "📋 Configuración RTP:"
	@docker exec freepbx cat /etc/asterisk/rtp_custom.conf 2>/dev/null | grep -v "^;" | grep -v "^$$" || echo "❌ No configurado"
	@echo ""
	@echo "📋 Configuración SIP:"
	@docker exec freepbx cat /etc/asterisk/sip_general_custom.conf 2>/dev/null | grep -v "^;" | grep -v "^$$" || echo "❌ No configurado"
	@echo ""
	@echo "📋 Configuración PJSIP:"
	@docker exec freepbx cat /etc/asterisk/pjsip_custom_post.conf 2>/dev/null | grep -v "^;" | grep -v "^$$" || echo "❌ No configurado"
	@echo ""
	@echo "🔍 Estado del endpoint ElevenLabs:"
	@docker exec freepbx asterisk -rx "pjsip show endpoint ElevenLabs" 2>/dev/null | grep -i -E "media|rtp|nat" | head -5 || echo "❌ No se pudo obtener"

# Ver logs de llamadas a ElevenLabs
logs-elevenlabs:
	@echo "📋 === LOGS DE LLAMADAS ELEVENLABS (últimas 100 líneas) ==="
	@docker exec freepbx tail -100 /var/log/asterisk/full | grep -i -E "elevenlabs|appbot|18093321631|DIALSTATUS|HANGUPCAUSE|rtp|audio" | tail -50

# =====================================================
# MODO DESARROLLO/PRODUCCIÓN
# =====================================================

# Configurar modo desarrollo: llamadas salen por Zoiper (1001)
development:
	@echo "🔧 === CONFIGURANDO MODO DESARROLLO ==="
	@echo "📞 Todos los DIDs se redirigirán a Zoiper (extensión 1001)"
	@docker exec freepbx sh -c 'printf "%s\\n" \
"; =====================================================" \
"; CONFIGURACIÓN MODO DESARROLLO" \
"; Todos los DIDs van a extensión 1001" \
"; =====================================================" \
"" \
"; Hook para llamadas entrantes del trunk pillardhld (Altice)" \
"[from-trunk-pjsip-pillardhld-custom]" \
"exten => _.,1,NoOp(=== MODO DESARROLLO: Llamada desde Altice - DID: \$${EXTEN} - CALLER: \$${CALLERID(num)} ===)" \
" same => n,Set(__FROM_DID=\$${EXTEN})" \
" same => n,Set(CDR(userfield)=Development-Mode)" \
" same => n,Goto(from-trunk,\$${EXTEN},1)" \
"" \
"; Contextos DID personalizados (modo desarrollo -> extensión 1001)" \
"[ext-did-0002]" \
"exten => 8093321631,1,NoOp(=== DEV: DID 809-332-1631 -> Ext 1001 ===)" \
" same => n,Goto(ext-local,1001,1)" \
"exten => 8098093321631,1,NoOp(=== DEV: DID 809-332-1631 (Altice format) -> Ext 1001 ===)" \
" same => n,Goto(ext-local,1001,1)" \
"" \
"[ext-did-0003]" \
"exten => 8093328039,1,NoOp(=== DEV: DID 809-332-8039 -> Ext 1001 ===)" \
" same => n,Goto(ext-local,1001,1)" \
"exten => 8098093328039,1,NoOp(=== DEV: DID 809-332-8039 (Altice format) -> Ext 1001 ===)" \
" same => n,Goto(ext-local,1001,1)" \
"" \
"[ext-did-0004]" \
"exten => 8094759173,1,NoOp(=== DEV: DID 809-475-9173 -> Ext 1001 ===)" \
" same => n,Goto(ext-local,1001,1)" \
"exten => 8098094759173,1,NoOp(=== DEV: DID 809-475-9173 (Altice format) -> Ext 1001 ===)" \
" same => n,Goto(ext-local,1001,1)" \
"" \
"[ext-did-0005]" \
"exten => 8093341622,1,NoOp(=== DEV: DID 809-334-1622 -> Ext 1001 ===)" \
" same => n,Goto(ext-local,1001,1)" \
"exten => 8098093341622,1,NoOp(=== DEV: DID 809-334-1622 (Altice format) -> Ext 1001 ===)" \
" same => n,Goto(ext-local,1001,1)" \
"" \
"[ext-did-0006]" \
"exten => 8093341697,1,NoOp(=== DEV: DID 809-334-1697 -> Ext 1001 ===)" \
" same => n,Goto(ext-local,1001,1)" \
"exten => 8098093341697,1,NoOp(=== DEV: DID 809-334-1697 (Altice format) -> Ext 1001 ===)" \
" same => n,Goto(ext-local,1001,1)" \
"" \
"[ext-did-0007]" \
"exten => 8093341709,1,NoOp(=== DEV: DID 809-334-1709 -> Ext 1001 ===)" \
" same => n,Goto(ext-local,1001,1)" \
"exten => 8098093341709,1,NoOp(=== DEV: DID 809-334-1709 (Altice format) -> Ext 1001 ===)" \
" same => n,Goto(ext-local,1001,1)" \
"" \
"[ext-did-custom]" \
"include => ext-did-0002" \
"include => ext-did-0003" \
"include => ext-did-0004" \
"include => ext-did-0005" \
"include => ext-did-0006" \
"include => ext-did-0007" \
> /etc/asterisk/extensions_custom.conf'
	@docker exec freepbx asterisk -rx "dialplan reload"
	@echo ""
	@echo "✅ Modo desarrollo activado"
	@echo "📞 Todos los DIDs ahora timbran en extensión 1001 (Zoiper)"
	@echo "   • 809-332-1631 → Ext 1001"
	@echo "   • 809-332-8039 → Ext 1001"
	@echo "   • 809-475-9173 → Ext 1001"
	@echo "   • 809-334-1622 → Ext 1001"
	@echo "   • 809-334-1697 → Ext 1001"
	@echo "   • 809-334-1709 → Ext 1001"
	@echo "💡 Para activar ElevenLabs, ejecuta: make production"

# Configurar modo producción: cada DID va a su bot de ElevenLabs
production:
	@echo "🔧 === CONFIGURANDO MODO PRODUCCIÓN ==="
	@echo "📞 Cada DID se redirigirá a su bot de ElevenLabs correspondiente"
	@docker exec freepbx sh -c 'printf "%s\\n" \
"; =====================================================" \
"; CONFIGURACIÓN MODO PRODUCCIÓN" \
"; Cada DID va a su bot de ElevenLabs" \
"; =====================================================" \
"" \
"; Hook para llamadas entrantes del trunk pillardhld (Altice)" \
"[from-trunk-pjsip-pillardhld-custom]" \
"exten => _.,1,NoOp(=== MODO PRODUCCIÓN: Llamada desde Altice - DID: \$${EXTEN} - CALLER: \$${CALLERID(num)} ===)" \
" same => n,Set(__FROM_DID=\$${EXTEN})" \
" same => n,Set(CDR(userfield)=Production-Mode)" \
" same => n,Goto(from-trunk,\$${EXTEN},1)" \
"" \
"; Contextos DID personalizados (modo producción -> ElevenLabs)" \
"[ext-did-0002]" \
"exten => 8093321631,1,NoOp(=== PROD: DID 809-332-1631 -> ElevenLabs_1631 ===)" \
" same => n,Set(CDR(userfield)=ElevenLabs-1631)" \
" same => n,Answer()" \
" same => n,Wait(1)" \
" same => n,Dial(PJSIP/+18093321631@ElevenLabs_1631,180,tT)" \
" same => n,Hangup()" \
"exten => 8098093321631,1,NoOp(=== PROD: DID 809-332-1631 (Altice format) -> ElevenLabs_1631 ===)" \
" same => n,Set(CDR(userfield)=ElevenLabs-1631)" \
" same => n,Answer()" \
" same => n,Wait(1)" \
" same => n,Dial(PJSIP/+18093321631@ElevenLabs_1631,180,tT)" \
" same => n,Hangup()" \
"" \
"[ext-did-0003]" \
"exten => 8093328039,1,NoOp(=== PROD: DID 809-332-8039 -> ElevenLabs_8039 ===)" \
" same => n,Set(CDR(userfield)=ElevenLabs-8039)" \
" same => n,Answer()" \
" same => n,Wait(1)" \
" same => n,Dial(PJSIP/+18093328039@ElevenLabs_8039,180,tT)" \
" same => n,Hangup()" \
"exten => 8098093328039,1,NoOp(=== PROD: DID 809-332-8039 (Altice format) -> ElevenLabs_8039 ===)" \
" same => n,Set(CDR(userfield)=ElevenLabs-8039)" \
" same => n,Answer()" \
" same => n,Wait(1)" \
" same => n,Dial(PJSIP/+18093328039@ElevenLabs_8039,180,tT)" \
" same => n,Hangup()" \
"" \
"[ext-did-0004]" \
"exten => 8094759173,1,NoOp(=== PROD: DID 809-475-9173 -> ElevenLabs_9173 ===)" \
" same => n,Set(CDR(userfield)=ElevenLabs-9173)" \
" same => n,Answer()" \
" same => n,Wait(1)" \
" same => n,Dial(PJSIP/+18094759173@ElevenLabs_9173,180,tT)" \
" same => n,Hangup()" \
"exten => 8098094759173,1,NoOp(=== PROD: DID 809-475-9173 (Altice format) -> ElevenLabs_9173 ===)" \
" same => n,Set(CDR(userfield)=ElevenLabs-9173)" \
" same => n,Answer()" \
" same => n,Wait(1)" \
" same => n,Dial(PJSIP/+18094759173@ElevenLabs_9173,180,tT)" \
" same => n,Hangup()" \
"" \
"[ext-did-0005]" \
"exten => 8093341622,1,NoOp(=== PROD: DID 809-334-1622 -> ElevenLabs_1622 ===)" \
" same => n,Set(CDR(userfield)=ElevenLabs-1622)" \
" same => n,Answer()" \
" same => n,Wait(1)" \
" same => n,Dial(PJSIP/+18093341622@ElevenLabs_1622,180,tT)" \
" same => n,Hangup()" \
"exten => 8098093341622,1,NoOp(=== PROD: DID 809-334-1622 (Altice format) -> ElevenLabs_1622 ===)" \
" same => n,Set(CDR(userfield)=ElevenLabs-1622)" \
" same => n,Answer()" \
" same => n,Wait(1)" \
" same => n,Dial(PJSIP/+18093341622@ElevenLabs_1622,180,tT)" \
" same => n,Hangup()" \
"" \
"[ext-did-0006]" \
"exten => 8093341697,1,NoOp(=== PROD: DID 809-334-1697 -> ElevenLabs_1697 ===)" \
" same => n,Set(CDR(userfield)=ElevenLabs-1697)" \
" same => n,Answer()" \
" same => n,Wait(1)" \
" same => n,Dial(PJSIP/+18093341697@ElevenLabs_1697,180,tT)" \
" same => n,Hangup()" \
"exten => 8098093341697,1,NoOp(=== PROD: DID 809-334-1697 (Altice format) -> ElevenLabs_1697 ===)" \
" same => n,Set(CDR(userfield)=ElevenLabs-1697)" \
" same => n,Answer()" \
" same => n,Wait(1)" \
" same => n,Dial(PJSIP/+18093341697@ElevenLabs_1697,180,tT)" \
" same => n,Hangup()" \
"" \
"[ext-did-0007]" \
"exten => 8093341709,1,NoOp(=== PROD: DID 809-334-1709 -> ElevenLabs_1709 ===)" \
" same => n,Set(CDR(userfield)=ElevenLabs-1709)" \
" same => n,Answer()" \
" same => n,Wait(1)" \
" same => n,Dial(PJSIP/+18093341709@ElevenLabs_1709,180,tT)" \
" same => n,Hangup()" \
"exten => 8098093341709,1,NoOp(=== PROD: DID 809-334-1709 (Altice format) -> ElevenLabs_1709 ===)" \
" same => n,Set(CDR(userfield)=ElevenLabs-1709)" \
" same => n,Answer()" \
" same => n,Wait(1)" \
" same => n,Dial(PJSIP/+18093341709@ElevenLabs_1709,180,tT)" \
" same => n,Hangup()" \
"" \
"[ext-did-custom]" \
"include => ext-did-0002" \
"include => ext-did-0003" \
"include => ext-did-0004" \
"include => ext-did-0005" \
"include => ext-did-0006" \
"include => ext-did-0007" \
> /etc/asterisk/extensions_custom.conf'
	@docker exec freepbx asterisk -rx "dialplan reload"
	@echo ""
	@echo "✅ Modo producción activado"
	@echo "📞 Cada DID ahora se conecta con su bot de ElevenLabs:"
	@echo "   • 809-332-1631 → ElevenLabs_1631"
	@echo "   • 809-332-8039 → ElevenLabs_8039"
	@echo "   • 809-475-9173 → ElevenLabs_9173"
	@echo "   • 809-334-1622 → ElevenLabs_1622"
	@echo "   • 809-334-1697 → ElevenLabs_1697"
	@echo "   • 809-334-1709 → ElevenLabs_1709"
	@echo "💡 Para volver a desarrollo, ejecuta: make development"

# Verificar modo actual (desarrollo o producción)
mode:
	@echo "🔍 === VERIFICANDO MODO ACTUAL ==="
	@if docker exec freepbx cat /etc/asterisk/extensions_custom.conf | grep -q "MODO DESARROLLO"; then \
		echo "✅ Modo: DESARROLLO"; \
		echo "📞 Llamadas -> Extensión 1001 (Zoiper)"; \
	elif docker exec freepbx cat /etc/asterisk/extensions_custom.conf | grep -q "MODO PRODUCCIÓN"; then \
		echo "✅ Modo: PRODUCCIÓN"; \
		echo "📞 Llamadas -> ElevenLabs (cada DID a su bot)"; \
	else \
		echo "❌ No se pudo determinar el modo"; \
	fi

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
	@echo "📦 Exportando directorios de configuración..."
	@if [ -d "./config/freepbx" ] && [ "$$(ls -A ./config/freepbx 2>/dev/null)" ]; then \
		tar czf $(BACKUP_DIR)/freepbx_data.tar.gz -C ./config/freepbx .; \
		echo "✅ freepbx_data exportado"; \
	else \
		echo "⚠️  No se encontró ./config/freepbx o está vacío"; \
	fi
	@if [ -d "./config/mysql" ] && [ "$$(ls -A ./config/mysql 2>/dev/null)" ]; then \
		tar czf $(BACKUP_DIR)/freepbx_db.tar.gz -C ./config/mysql .; \
		echo "✅ freepbx_db exportado"; \
	else \
		echo "⚠️  No se encontró ./config/mysql o está vacío"; \
	fi
	@if [ -d "./config/www" ] && [ "$$(ls -A ./config/www 2>/dev/null)" ]; then \
		tar czf $(BACKUP_DIR)/freepbx_www.tar.gz -C ./config/www .; \
		echo "✅ freepbx_www exportado"; \
	else \
		echo "⚠️  No se encontró ./config/www o está vacío"; \
	fi
	@if [ -d "./config/logs" ] && [ "$$(ls -A ./config/logs 2>/dev/null)" ]; then \
		tar czf $(BACKUP_DIR)/freepbx_logs.tar.gz -C ./config/logs .; \
		echo "✅ freepbx_logs exportado"; \
	else \
		echo "⚠️  No se encontró ./config/logs o está vacío"; \
	fi
	@if [ -d "./config/asterisk" ] && [ "$$(ls -A ./config/asterisk 2>/dev/null)" ]; then \
		tar czf $(BACKUP_DIR)/freepbx_asterisk.tar.gz -C ./config/asterisk .; \
		echo "✅ freepbx_asterisk exportado"; \
	fi
	@echo "▶️  Reiniciando contenedor..."
	@docker compose up -d
	@echo ""
	@echo "🎉 Backup completado! Archivos en: $(BACKUP_DIR)/"
	@ls -lh $(BACKUP_DIR)/ 2>/dev/null || true

# Restaurar backup
restore:
	@echo "♻️ === RESTAURANDO BACKUP ==="
	@echo "🔍 Verificando backups..."
	@if [ ! -d "$(BACKUP_DIR)" ]; then \
		echo "❌ Error: No se encontró el directorio $(BACKUP_DIR)"; \
		exit 1; \
	fi
	@echo "🛑 Deteniendo contenedor si está corriendo..."
	@docker compose down 2>/dev/null || true
	@echo "📦 Creando directorios de configuración..."
	@mkdir -p ./config/freepbx ./config/mysql ./config/www ./config/logs ./config/asterisk
	@echo "🔄 Restaurando archivos desde backup..."
	@if [ -f "$(BACKUP_DIR)/freepbx_data.tar.gz" ]; then \
		echo "📂 Restaurando freepbx_data..."; \
		tar xzf $(BACKUP_DIR)/freepbx_data.tar.gz -C ./config/freepbx/ 2>/dev/null || true; \
		echo "✅ freepbx_data restaurado"; \
	else \
		echo "⚠️  No se encontró freepbx_data.tar.gz"; \
	fi
	@if [ -f "$(BACKUP_DIR)/freepbx_db.tar.gz" ]; then \
		echo "📂 Restaurando freepbx_db..."; \
		tar xzf $(BACKUP_DIR)/freepbx_db.tar.gz -C ./config/mysql/ 2>/dev/null || true; \
		echo "✅ freepbx_db restaurado"; \
	else \
		echo "⚠️  No se encontró freepbx_db.tar.gz"; \
	fi
	@if [ -f "$(BACKUP_DIR)/freepbx_www.tar.gz" ]; then \
		echo "📂 Restaurando freepbx_www..."; \
		tar xzf $(BACKUP_DIR)/freepbx_www.tar.gz -C ./config/www/ 2>/dev/null || true; \
		echo "✅ freepbx_www restaurado"; \
	else \
		echo "⚠️  No se encontró freepbx_www.tar.gz"; \
	fi
	@if [ -f "$(BACKUP_DIR)/freepbx_logs.tar.gz" ]; then \
		echo "📂 Restaurando freepbx_logs..."; \
		tar xzf $(BACKUP_DIR)/freepbx_logs.tar.gz -C ./config/logs/ 2>/dev/null || true; \
		echo "✅ freepbx_logs restaurado"; \
	else \
		echo "⚠️  No se encontró freepbx_logs.tar.gz"; \
	fi
	@if [ -f "$(BACKUP_DIR)/freepbx_asterisk.tar.gz" ]; then \
		echo "📂 Restaurando freepbx_asterisk..."; \
		tar xzf $(BACKUP_DIR)/freepbx_asterisk.tar.gz -C ./config/asterisk/ 2>/dev/null || true; \
		echo "✅ freepbx_asterisk restaurado"; \
	fi
	@echo "🔧 Ajustando permisos..."
	@sudo chown -R 1000:1000 ./config/freepbx ./config/www ./config/logs ./config/asterisk 2>/dev/null || chown -R 1000:1000 ./config/freepbx ./config/www ./config/logs ./config/asterisk 2>/dev/null || true
	@sudo chown -R 999:999 ./config/mysql 2>/dev/null || chown -R 999:999 ./config/mysql 2>/dev/null || true
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
	@if ip link show $(USB_INTERFACE) 2>/dev/null | grep -q $(USB_INTERFACE); then \
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
			mkdir -p ./config/freepbx ./config/mysql ./config/www ./config/logs ./config/asterisk; \
			tar xzf $(BACKUP_DIR)/freepbx_data.tar.gz -C ./config/freepbx/ 2>/dev/null || true; \
			tar xzf $(BACKUP_DIR)/freepbx_db.tar.gz -C ./config/mysql/ 2>/dev/null || true; \
			tar xzf $(BACKUP_DIR)/freepbx_www.tar.gz -C ./config/www/ 2>/dev/null || true; \
			tar xzf $(BACKUP_DIR)/freepbx_logs.tar.gz -C ./config/logs/ 2>/dev/null || true; \
			if [ -f "$(BACKUP_DIR)/freepbx_asterisk.tar.gz" ]; then \
				tar xzf $(BACKUP_DIR)/freepbx_asterisk.tar.gz -C ./config/asterisk/ 2>/dev/null || true; \
			fi; \
			sudo chown -R 1000:1000 ./config/freepbx ./config/www ./config/logs ./config/asterisk 2>/dev/null || chown -R 1000:1000 ./config/freepbx ./config/www ./config/logs ./config/asterisk 2>/dev/null || true; \
			sudo chown -R 999:999 ./config/mysql 2>/dev/null || chown -R 999:999 ./config/mysql 2>/dev/null || true; \
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
	@echo "╠════════════════════════════════════════════════════════════╣"
	@echo "║  NAT/AUDIO:                                                ║"
	@echo "║    make configure-nat - Configurar NAT/IP externa (auto)   ║"
	@echo "║    make check-nat     - Verificar configuración NAT        ║"
	@echo "║    make logs-elevenlabs - Logs de llamadas ElevenLabs      ║"
	@echo "╠════════════════════════════════════════════════════════════╣"
	@echo "║  DESARROLLO/PRODUCCIÓN:                                    ║"
	@echo "║    make development  - Modo desarrollo (llamadas a Zoiper)║"
	@echo "║    make production    - Modo producción (llamadas a ElevenLabs)║"
	@echo "║    make mode          - Verificar modo actual              ║"
	@echo "╚════════════════════════════════════════════════════════════╝"
