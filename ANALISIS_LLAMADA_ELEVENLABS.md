# 🔍 Análisis Detallado de Llamada a ElevenLabs

## 📊 Resumen del Problema

**Síntoma:** La llamada se establece pero muestra "no call" con duración 0.00s en el trunk SIP.

**Realidad:** La llamada SÍ se establece correctamente, pero hay problemas en el procesamiento.

---

## ✅ Lo que SÍ funciona:

1. **Establecimiento de Llamada:**
   - ✅ INVITE se envía correctamente a `sip:+18093321631@sip.rtc.elevenlabs.io:5060`
   - ✅ Autenticación funciona (401 → reenvío con Proxy-Authorization)
   - ✅ Se recibe 180 Ringing
   - ✅ Se recibe 200 OK (llamada contestada)
   - ✅ Canal se pone en estado "Up"
   - ✅ Bridge se establece entre canales
   - ✅ RTP/RTCP está funcionando

2. **Configuración SIP:**
   - ✅ Endpoint ElevenLabs configurado
   - ✅ AOR disponible
   - ✅ Transport TCP funcionando
   - ✅ Autenticación correcta

---

## ❌ Problemas Identificados:

### 1. **Problema de Identificación de Endpoint**
```
[2025-12-26 11:27:53] DEBUG: Source address 192.168.100.200:43358 does not match identify 'ElevenLabs'
```

**Causa:** El endpoint `ElevenLabs` tiene un `identify` configurado que solo acepta la IP `34.29.130.129/32`, pero las respuestas pueden venir de otras IPs o el tráfico interno (192.168.100.200) no coincide.

**Impacto:** Puede causar problemas con mensajes SIP entrantes o re-INVITEs.

### 2. **Contexto Incorrecto**
- **Contexto actual:** `from-trunk`
- **Contexto esperado:** `to-elevenlabs-bot` o similar
- **Extensión:** Vacía

**Causa:** El endpoint está configurado con `context=from-trunk` en lugar de un contexto que procese la llamada correctamente.

### 3. **CDR Muestra Información Incorrecta**
```
duration=2
billsec=0
disposition=8 (NOANSWER o similar)
```

**Problema:** Aunque la llamada se establece (200 OK), el CDR muestra que no se contestó o duró muy poco.

### 4. **Bridge no puede usar Native RTP**
```
Bridge can not use native RTP bridge as channel 'PJSIP/ElevenLabs-00000005' has DTMF hooks
```

**Impacto:** El bridge usa transcodificación en lugar de native RTP, lo que puede causar latencia o problemas de audio.

---

## 🔧 Soluciones Propuestas:

### Solución 1: Ajustar Identify del Endpoint

El identify actual solo acepta la IP del servidor de ElevenLabs. Necesitamos permitir también tráfico interno:

```ini
[ElevenLabs]
type=identify
endpoint=ElevenLabs
match=sip.rtc.elevenlabs.io
match=192.168.100.200/32  # Agregar IP interna
```

### Solución 2: Cambiar Contexto del Endpoint

El contexto `from-trunk` es para llamadas entrantes. Para llamadas salientes, debería ser diferente o el endpoint debería procesar correctamente:

```ini
[ElevenLabs]
context=from-internal  # O un contexto específico para procesar
```

### Solución 3: Verificar Configuración de Direct Media

El endpoint tiene `direct_media=no`, lo que está bien, pero verificar que RTP esté funcionando correctamente.

### Solución 4: Revisar Configuración de DTMF

El problema del bridge con DTMF hooks sugiere que hay hooks configurados que impiden native RTP. Revisar si se necesitan.

---

## 📝 Logs Clave Capturados:

### Flujo de Llamada:
1. **11:27:41** - INVITE enviado
2. **11:27:41** - 401 Unauthorized (autenticación requerida)
3. **11:27:41** - INVITE reenviado con Proxy-Authorization
4. **11:27:41-42** - 180 Ringing (múltiples)
5. **11:27:43** - 200 OK (llamada contestada)
6. **11:27:43** - Bridge establecido
7. **11:27:43** - CDR finalizado (duration=2, billsec=0)

### Estado del Canal:
- **Estado:** Up (conectado)
- **Tiempo activo:** 45+ segundos
- **RTP:** Funcionando (RTCP sent)
- **Formato:** ulaw (compatible)

---

## 🎯 Próximos Pasos:

1. **Ajustar identify** para permitir tráfico interno
2. **Revisar contexto** del endpoint
3. **Verificar configuración de DTMF** si es necesario
4. **Monitorear una llamada completa** desde inicio hasta fin
5. **Revisar logs de ElevenLabs** para ver su perspectiva

---

## 📊 Conclusión:

La llamada **SÍ se establece correctamente** a nivel SIP. El problema parece estar en:
1. La identificación del endpoint que rechaza algunos mensajes
2. El contexto que no procesa la llamada correctamente
3. Posible problema con el procesamiento del CDR o la duración de la llamada

**La señalización SIP funciona, pero hay problemas en el procesamiento interno de Asterisk.**

