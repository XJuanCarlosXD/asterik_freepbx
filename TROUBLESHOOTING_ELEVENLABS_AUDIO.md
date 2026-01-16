# 🔧 Solución: Problema de Audio con ElevenLabs

## 📋 Problema Identificado

Cuando se realiza una llamada a ElevenLabs:
- ✅ La señalización SIP funciona correctamente (la llamada se establece)
- ❌ No hay audio (el bot no responde o no se escucha voz)
- ❌ En los logs de ElevenLabs aparece que "nunca respondió" o "no mandó el bot"

### Causa Raíz

El problema es que **Asterisk está enviando una IP privada en el SDP** (Session Description Protocol) en lugar de la IP pública. Esto hace que ElevenLabs no pueda enviar el tráfico RTP (audio) de vuelta al servidor.

**Ejemplo del problema:**
```
SDP enviado por Asterisk:
c=IN IP4 152.167.82.212  ← IP privada/interna
```

ElevenLabs intenta enviar RTP a esa IP, pero como es privada, no puede alcanzarla desde internet.

## ✅ Solución Aplicada

Se ha configurado automáticamente la IP externa en los archivos de configuración:

1. **`/etc/asterisk/rtp_custom.conf`** - Configuración de RTP con IP externa
2. **`/etc/asterisk/sip_general_custom.conf`** - Configuración NAT para SIP
3. **`/etc/asterisk/pjsip_custom_post.conf`** - Configuración para PJSIP

### Comandos Disponibles

```bash
# Configurar NAT automáticamente (detecta IP externa)
make configure-nat

# Verificar la configuración NAT
make check-nat

# Ver logs de llamadas a ElevenLabs
make logs-elevenlabs
```

## 🔍 Verificación

### 1. Verificar que la configuración está aplicada:

```bash
make check-nat
```

Deberías ver:
- IP Externa detectada: `152.167.82.212` (o tu IP pública)
- Configuración RTP con `externip` configurado
- Configuración SIP con `externip` y `nat` configurados

### 2. Probar una llamada

Realiza una llamada a ElevenLabs y verifica:
- La llamada se establece (SIP funciona)
- Se escucha audio del bot
- El bot responde correctamente

### 3. Ver logs de la llamada

```bash
make logs-elevenlabs
```

Busca en los logs:
- `DIALSTATUS=ANSWER` - La llamada fue contestada
- `HANGUPCAUSE` - Razón del cuelgue (si aplica)
- Errores relacionados con RTP o audio

## ⚠️ Si el Problema Persiste

Si después de aplicar la configuración el problema continúa, es posible que necesites configurar la IP externa desde la interfaz web de FreePBX:

### Pasos Adicionales (Interfaz Web FreePBX)

1. Accede a FreePBX: `http://localhost/admin` (o tu IP)
2. Ve a **Settings** → **Asterisk SIP Settings**
3. En la sección **NAT Settings**:
   - **External IP**: Ingresa tu IP pública (`152.167.82.212`)
   - **Local Networks**: Asegúrate de que estén configuradas las redes locales
4. Click en **Submit**
5. Click en **Apply Config** (botón rojo arriba)
6. Reinicia Asterisk: `make restart`

### Verificar desde la CLI de Asterisk

```bash
# Ver configuración SIP
docker exec freepbx asterisk -rx "sip show settings" | grep -i extern

# Ver logs en tiempo real durante una llamada
make logs
```

## 📊 Diagnóstico Avanzado

### Ver el SDP que se envía a ElevenLabs

```bash
docker exec freepbx tail -f /var/log/asterisk/full | grep -i "m=audio"
```

Busca líneas como:
```
m=audio 13092 RTP/AVP 0 8 107 101
c=IN IP4 152.167.82.212
```

La IP en la línea `c=IN IP4` debe ser tu **IP pública**, no una IP privada.

### Verificar conectividad RTP

```bash
# Ver canales activos
docker exec freepbx asterisk -rx "core show channels"

# Ver estadísticas RTP
docker exec freepbx asterisk -rx "rtp set debug on"
make logs
```

## 🔄 Reiniciar Configuración

Si necesitas reconfigurar NAT:

```bash
make configure-nat
make restart
```

## 📝 Notas Importantes

1. **IP Pública Dinámica**: Si tu IP pública cambia, ejecuta `make configure-nat` nuevamente.

2. **Firewall**: Asegúrate de que los puertos RTP (18000-18100 UDP) estén abiertos:
   ```bash
   sudo ufw allow 18000:18100/udp
   ```

3. **NAT Traversal**: La configuración aplicada usa `rtp_symmetric=yes` y `force_rport=yes` que ayudan con NAT traversal.

4. **PJSIP vs SIP**: Se configuró tanto para chan_sip (legacy) como para PJSIP (moderno).

## ✅ Checklist Final

- [ ] Configuración NAT aplicada (`make check-nat`)
- [ ] IP externa configurada correctamente
- [ ] Asterisk reiniciado después de la configuración
- [ ] Prueba de llamada realizada
- [ ] Audio funciona correctamente
- [ ] Logs verificados sin errores de RTP

## 🆘 Soporte

Si el problema persiste después de seguir estos pasos:

1. Revisa los logs completos: `make logs-elevenlabs`
2. Verifica la configuración: `make check-nat`
3. Revisa el estado de los trunks: `make status`
4. Verifica conectividad: `make ping-elevenlabs`

---

**Última actualización**: Configuración aplicada automáticamente
**IP Externa Configurada**: `152.167.82.212`

