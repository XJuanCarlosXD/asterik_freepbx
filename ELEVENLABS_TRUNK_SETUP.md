# 🎙️ Configuración del Trunk SIP de ElevenLabs en FreePBX

## Datos del Trunk ElevenLabs

| Campo | Valor |
|-------|-------|
| **SIP Server (TCP)** | `sip.rtc.elevenlabs.io:5060` |
| **SIP Server (TLS)** | `sip.rtc.elevenlabs.io:5061` |
| **Username** | `appbot_elevenlab` |
| **Password** | `123$appbot` |
| **Transport** | TCP o TLS |

---

## 📋 Pasos para Configurar el Trunk

### 1. Acceder a FreePBX

1. Abre tu navegador y ve a: `http://<IP-DEL-SERVIDOR>/admin`
2. Inicia sesión con tus credenciales de administrador

### 2. Crear el Trunk PJSIP

1. Ve a **Connectivity** → **Trunks**
2. Click en **+ Add Trunk** → **Add SIP (chan_pjsip) Trunk**

### 3. Configuración General

En la pestaña **General**:

| Campo | Valor |
|-------|-------|
| Trunk Name | `ElevenLabs` |
| Outbound CallerID | (tu número si tienes uno) |
| CID Options | `Allow Any CID` |
| Maximum Channels | `10` (o según tu plan) |

### 4. Configuración SIP (Pestaña pjsip Settings)

#### Tab "General":

| Campo | Valor |
|-------|-------|
| Username | `appbot_elevenlab` |
| Secret | `123$appbot` |
| Authentication | `Outbound` |
| Registration | `Send` |
| SIP Server | `sip.rtc.elevenlabs.io` |
| SIP Server Port | `5060` (TCP) o `5061` (TLS) |

#### Tab "Advanced":

| Campo | Valor |
|-------|-------|
| Transport | `0.0.0.0-tcp` (para TCP) o `0.0.0.0-tls` (para TLS) |
| From Domain | `sip.rtc.elevenlabs.io` |
| From User | `appbot_elevenlab` |
| Contact User | `appbot_elevenlab` |
| DTMF Mode | `RFC 4733` |
| Qualify Frequency | `60` |
| Media Encryption | `SRTP via in-SDP` (si usas TLS) o `None` (si usas TCP) |

### 5. Configuración de Codecs

En **Codecs**, asegúrate de tener habilitados (en orden de preferencia):
- ✅ `ulaw` (G.711 μ-law)
- ✅ `alaw` (G.711 A-law)
- ✅ `opus` (si está disponible)

### 6. Guardar y Aplicar

1. Click en **Submit**
2. Click en el botón rojo **Apply Config** en la parte superior

---

## 📞 Configuración de Rutas

### Ruta de Entrada (Inbound Route)

1. Ve a **Connectivity** → **Inbound Routes**
2. Click en **+ Add Inbound Route**
3. Configura:
   - **Description**: `ElevenLabs Inbound`
   - **DID Number**: (déjalo vacío para aceptar cualquier llamada del trunk)
   - **Trunk**: Selecciona `ElevenLabs`
   - **Set Destination**: Elige a dónde enviar las llamadas (extensión, IVR, etc.)
4. **Submit** y **Apply Config**

### Ruta de Salida (Outbound Route) - Si necesitas llamar hacia ElevenLabs

1. Ve a **Connectivity** → **Outbound Routes**
2. Click en **+ Add Outbound Route**
3. Configura:
   - **Route Name**: `ElevenLabs-Out`
   - **Trunk Sequence**: Selecciona `ElevenLabs`
   - **Dial Patterns**: Agrega el patrón según necesites
4. **Submit** y **Apply Config**

---

## 🔧 Configuración Alternativa via Asterisk CLI

Si prefieres configurar directamente en los archivos de Asterisk, aquí están los comandos:

### Verificar el estado del trunk:

```bash
docker exec -it freepbx asterisk -rx "pjsip show endpoints"
docker exec -it freepbx asterisk -rx "pjsip show registrations"
```

### Ver logs de SIP:

```bash
docker exec -it freepbx asterisk -rx "pjsip set logger on"
docker exec -it freepbx tail -f /var/log/asterisk/full
```

---

## 🔥 Configuración de Firewall

Asegúrate de que tu firewall permita:

| Puerto | Protocolo | Descripción |
|--------|-----------|-------------|
| 5060 | TCP | SIP (sin encriptación) |
| 5061 | TCP | SIP TLS (encriptado) |
| 18000-18100 | UDP | RTP (audio) |

### Comandos iptables (ejemplo):

```bash
# SIP TCP
sudo iptables -A INPUT -p tcp --dport 5060 -j ACCEPT
sudo iptables -A OUTPUT -p tcp --dport 5060 -j ACCEPT

# SIP TLS
sudo iptables -A INPUT -p tcp --dport 5061 -j ACCEPT
sudo iptables -A OUTPUT -p tcp --dport 5061 -j ACCEPT

# RTP
sudo iptables -A INPUT -p udp --dport 18000:18100 -j ACCEPT
sudo iptables -A OUTPUT -p udp --dport 18000:18100 -j ACCEPT
```

---

## 🧪 Troubleshooting

### El trunk no registra:

1. Verifica las credenciales
2. Revisa que el puerto 5060/5061 saliente esté abierto
3. Revisa los logs:
   ```bash
   docker exec -it freepbx asterisk -rx "pjsip show registrations"
   ```

### No hay audio:

1. Verifica que los puertos RTP (18000-18100) estén abiertos
2. Revisa que NAT esté bien configurado en FreePBX
3. Ve a **Settings** → **Asterisk SIP Settings** y configura tu IP externa

### Error de autenticación:

1. Verifica que el username sea exacto: `appbot_elevenlab`
2. Verifica el password: `123$appbot`
3. Asegúrate de que "Authentication" esté en "Outbound"

---

## ✅ Checklist Final

- [ ] Trunk creado en FreePBX
- [ ] Trunk registrado (verde en el dashboard)
- [ ] Ruta de entrada configurada
- [ ] Ruta de salida configurada (si aplica)
- [ ] Firewall configurado
- [ ] Prueba de llamada exitosa

---

**¡Listo mi loca! 🚀** Si tienes dudas, revisa los logs de Asterisk.

