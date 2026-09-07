#!/bin/bash

# =========================
# CONFIG
# =========================
WEBHOOK_URL="https://discord.com/api/webhooks/?????"
ALERT_VERSION="v3.0"
SERVER_NAME=$(hostname)

LOG_FILE="/var/log/db_maintenance.log"

# swap config
SWAP_CLEAR_ENABLE=1
MIN_FREE_RAM_MB=1024

# =========================
# LOGGER
# =========================
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# =========================
# DISCORD FUNCTION
# =========================
send_discord_embed() {
    local TITLE="$1"
    local DESCRIPTION="$2"
    local COLOR="$3"

    curl -s -H "Content-Type: application/json" \
        -X POST \
        -d "{
            \"embeds\": [{
                \"title\": \"$TITLE\",
                \"description\": \"$DESCRIPTION\",
                \"color\": $COLOR,
                \"footer\": { \"text\": \"DB Maintenance $ALERT_VERSION\" },
                \"timestamp\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\"
            }]
        }" \
        "$WEBHOOK_URL" >/dev/null 2>&1
}

# =========================
# START
# =========================
log "=============================="
log "DB Maintenance START - $SERVER_NAME"
log "=============================="

FREE_RAM=$(free -m | awk '/Mem:/ {print $7}')
USED_SWAP=$(free -m | awk '/Swap:/ {print $3}')

log "Free RAM: ${FREE_RAM} MB"
log "Used Swap: ${USED_SWAP} MB"

send_discord_embed \
"⚠️ DB Maintenance Scheduled - $SERVER_NAME" \
"Restart MySQL akan dilakukan dalam 1 menit.\nFree RAM: ${FREE_RAM} MB\nSwap Used: ${USED_SWAP} MB" \
15105570

sleep 60

# =========================
# SWAP CLEAR (SAFE MODE)
# =========================
log "Checking swap condition..."

if [ "$SWAP_CLEAR_ENABLE" -eq 1 ]; then

    if [ "$FREE_RAM" -ge "$MIN_FREE_RAM_MB" ] && [ "$USED_SWAP" -gt 0 ]; then

        log "Swap clear triggered (safe condition met)"

        send_discord_embed \
        "🧹 Swap Clearing" \
        "Swap sedang dibersihkan sebelum restart MySQL." \
        16753920

        swapoff -a
        swapon -a

        log "Swap cleared successfully"

    else
        log "Skip swap clear (RAM kurang / swap kosong)"
    fi
else
    log "Swap clear disabled by config"
fi

# =========================
# RESTART MYSQL
# =========================
log "Restarting MySQL..."

send_discord_embed \
"🔄 Restart MySQL" \
"Proses restart MySQL/MariaDB sedang berjalan di $SERVER_NAME" \
3447003

/scripts/restartsrv_mysql
STATUS_RESTART=$?

log "MySQL restart exit code: $STATUS_RESTART"

# =========================
# REPAIR DATABASE
# =========================
log "Running mysqlcheck -rA..."

mysqlcheck -rA
STATUS_REPAIR=$?

log "mysqlcheck exit code: $STATUS_REPAIR"

# =========================
# RESULT
# =========================
if [ $STATUS_RESTART -eq 0 ] && [ $STATUS_REPAIR -eq 0 ]; then

    log "DB Maintenance SUCCESS"

    send_discord_embed \
    "✅ DB Maintenance Success - $SERVER_NAME" \
    "Restart MySQL + Repair database berhasil.\nStatus: SUCCESS" \
    3066993

else

    log "DB Maintenance FAILED (restart=$STATUS_RESTART repair=$STATUS_REPAIR)"

    send_discord_embed \
    "❌ DB Maintenance Failed - $SERVER_NAME" \
    "Terjadi error saat maintenance.\nRestart: $STATUS_RESTART\nRepair: $STATUS_REPAIR" \
    15158332
fi

log "DB Maintenance FINISHED"
log "=============================="
