#!/bin/bash
echo "==================================="
echo "MONITOR DE LLAMADAS A ELEVENLABS"
echo "==================================="
echo ""
echo "Presiona Ctrl+C para salir"
echo ""
echo "Esperando llamada..."
echo ""

docker exec freepbx tail -f /var/log/asterisk/full | grep --line-buffered -E "INVITE|Answer|Dial|DIALSTATUS|RTP|audio|codec|SDP|media|ElevenLabs_|from-trunk-pjsip-pillardhld|ext-did|8093328039|8094759173|8093341622|8093341697|8093341709|CHANUNAVAIL|Unavailable|busy"
