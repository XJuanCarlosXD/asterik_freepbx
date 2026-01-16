# Configuración ElevenLabs - FreePBX

## DIDs Configurados

Cada uno de los siguientes números tiene su propio trunk y bot de ElevenLabs:

| Número          | Trunk ElevenLabs  | Phone Number ID                      |
|-----------------|-------------------|--------------------------------------|
| +1 809-332-8039 | ElevenLabs_8039   | phnum_4601kf3m2676entbkk9g69hjrh67  |
| +1 809-475-9173 | ElevenLabs_9173   | phnum_3301kf3m4919f04bgbe6s043ged8  |
| +1 809-334-1622 | ElevenLabs_1622   | phnum_6801kf3m7za0eewv70cabx21387v  |
| +1 809-334-1697 | ElevenLabs_1697   | phnum_8801kf3mabd8ezp855b97pd5v8md  |
| +1 809-334-1709 | ElevenLabs_1709   | phnum_8001kf3mc0qhf3gt14qat5n7rc9s  |

## Credenciales ElevenLabs

- **Usuario**: appbot_elevenlab
- **Contraseña**: 123$appbot
- **Servidor**: sip.rtc.elevenlabs.io:5060 (TCP)

## Modos de Operación

### Modo Desarrollo
```bash
make development
```

En este modo:
- **Todas** las llamadas entrantes a los 5 DIDs se redirigen a la extensión 1001 (Zoiper)
- Útil para probar sin consumir créditos de ElevenLabs
- Permite verificar que las llamadas llegan correctamente

### Modo Producción
```bash
make production
```

En este modo:
- Cada DID se conecta con su **propio bot de ElevenLabs**
- Las llamadas entrantes se responden y transfieren automáticamente a ElevenLabs
- Cada número tiene su configuración independiente

### Verificar Modo Actual
```bash
make mode
```

Muestra si estás en modo desarrollo o producción.

## Comandos Útiles

```bash
# Ver estado de todos los trunks
make status

# Ver logs en tiempo real
make logs

# Ver registros de trunks
make registrations

# Reiniciar FreePBX
make restart

# Recargar configuración
make reload
```

## Formato de DIDs

Los DIDs aceptan **dos formatos** porque Altice envía los números con "809" duplicado:

- **Formato estándar**: 8093341697 (10 dígitos)
- **Formato Altice**: 8098093341697 (13 dígitos con 809 duplicado)

Ambos formatos funcionan correctamente y se redirigen al mismo destino.

## Arquitectura

```
Altice (Trunk pillardhld)
    ↓
FreePBX (from-trunk-pjsip-pillardhld-custom)
    ↓
ext-did-custom (incluye ext-did-0003 a ext-did-0007)
    ↓
    ├── DESARROLLO: → Extensión 1001 (Zoiper)
    └── PRODUCCIÓN: → ElevenLabs (trunk específico por DID)
```

## Archivos Importantes

- **Makefile**: Contiene los comandos `development`, `production`, y `mode`
- **extensions_custom.conf**: Dialplan personalizado (se genera automáticamente)
- **pjsip_custom_post.conf**: Configuración de trunks ElevenLabs
- **numero.md**: Mapeo de DIDs a Phone Number IDs de ElevenLabs

## Notas

1. Los endpoints ElevenLabs pueden mostrar "Unavailable" en el status, pero esto no afecta las llamadas salientes
2. En modo producción, cada llamada entrante se Answer() y luego se Dial() al trunk correspondiente
3. El modo se persiste en el archivo `/etc/asterisk/extensions_custom.conf` dentro del contenedor
4. Los cambios de modo requieren `dialplan reload`, que se hace automáticamente

## Troubleshooting

### Las llamadas no llegan a ElevenLabs

1. Verificar el modo actual: `make mode`
2. Ver logs en tiempo real: `make logs`
3. Verificar estado de endpoints: `make status`
4. Verificar que el dialplan esté cargado: 
   ```bash
   docker exec freepbx asterisk -rx "dialplan show 8093341697@ext-did"
   ```

### Las llamadas no llegan a la extensión 1001

1. Verificar que estás en modo desarrollo: `make mode`
2. Verificar que la extensión 1001 esté registrada: `make status`
3. Cambiar a modo desarrollo: `make development`

## Contacto ElevenLabs

- Servidor SIP: sip.rtc.elevenlabs.io:5060 (TCP)
- Servidor TLS: sip.rtc.elevenlabs.io:5061 (TLS)
- IP match: 136.112.48.140/32





