#!/bin/bash

WEBHOOK_URL="https://discord.com/api/webhooks/?????"
ALERT_VERSION="v1.1"
SERVER_NAME=$(hostname)

send_discord_embed() {
    local TITLE="$1"
    local DESCRIPTION="$2"
    local COLOR="$3"

    curl -H "Content-Type: application/json" \
        -X POST \
        -d "{
            \"embeds\": [{
                \"title\": \"$TITLE\",
                \"description\": \"$DESCRIPTION\",
                \"color\": $COLOR,
                \"footer\": { \"text\": \"Alerting restart db $ALERT_VERSION\" },
                \"timestamp\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\"
            }]
        }" \
        "$WEBHOOK_URL" >/dev/null 2>&1
}

echo "  Mengirim alert: Restart Database H-1 menit..."
send_discord_embed \
    "⚠️ Restart Database Terjadwal - $SERVER_NAME" \
    "Restart MySQL akan dilakukan dalam **1 menit**.\nServer: **$SERVER_NAME**" \
    15105570

sleep 60

echo "🔄 Alert: Proses restart sedang berjalan..."
send_discord_embed \
    "🔄 Proses Restart Database" \
    "Restart MySQL/MariaDB sedang berjalan...\nServer: **$SERVER_NAME**" \
    3447003

echo "⏳ Menjalankan restart MySQL..."
/scripts/restartsrv_mysql
STATUS_RESTART=$?

if [ $STATUS_RESTART -eq 0 ]; then
    echo "✅ Restart MySQL selesai."
else
    echo "❌ Restart MySQL gagal! Exit code: $STATUS_RESTART"
fi

echo "🛠 Memulai repair semua database dengan mysqlcheck -rA..."
mysqlcheck -rA
STATUS_REPAIR=$?

if [ $STATUS_REPAIR -eq 0 ]; then
    echo "✅ Repair database selesai."
else
    echo "❌ Repair database ada error! Exit code: $STATUS_REPAIR"
fi

if [ $STATUS_RESTART -eq 0 ] && [ $STATUS_REPAIR -eq 0 ]; then
    send_discord_embed \
        "✅ Restart & Repair Database Selesai - $SERVER_NAME" \
        "Restart MySQL dan repair semua database berhasil.\nStatus: **SUKSES**" \
        3066993
else
    send_discord_embed \
 "❌ Restart & Repair Database Gagal - $SERVER_NAME" \
        "Terjadi error saat restart atau repair database.\nRestart Exit: $STATUS_RESTART\nRepair Exit: $STATUS_REPAIR" \
        15158332
fi

