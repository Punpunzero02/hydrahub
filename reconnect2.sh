#!/data/data/com.termux/files/usr/bin/bash

PKG1="com.roblox.nodey"
PKG2="com.roblox.nodez"
CHECK_INTERVAL=10
LOG_FILE="/storage/emulated/0/roblox_reconnect.log"
CONFIG_FILE="/data/local/tmp/roblox_config.cfg"

STATE_DIR="/data/local/tmp/rbx_state"
FILE_LAST_RECONNECT1="$STATE_DIR/last_reconnect1"
FILE_LAST_RECONNECT2="$STATE_DIR/last_reconnect2"
FILE_IN_BACKGROUND1="$STATE_DIR/in_background1"
FILE_IN_BACKGROUND2="$STATE_DIR/in_background2"
FILE_LAST_RELOG1="$STATE_DIR/last_relog1"
FILE_LAST_RELOG2="$STATE_DIR/last_relog2"
FILE_RECONNECTING1="$STATE_DIR/reconnecting1"
FILE_RECONNECTING2="$STATE_DIR/reconnecting2"

RECONNECT_COOLDOWN=45
MONITOR_PID1=""
MONITOR_PID2=""
LAST_VERBOSE=0
VERBOSE_INTERVAL=600

load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
    fi
}

save_config() {
    cat > "$CONFIG_FILE" <<EOF
URL="$URL"
RELOG_SETIAP_JAM=$RELOG_SETIAP_JAM
RECONNECT_OTOMATIS=$RECONNECT_OTOMATIS
RESTART_KALAU_CRASH=$RESTART_KALAU_CRASH
RECONNECT_SAAT_HOME=$RECONNECT_SAAT_HOME
EOF
}

default_config() {
    URL=""
    RELOG_SETIAP_JAM=1
    RECONNECT_OTOMATIS=1
    RESTART_KALAU_CRASH=1
    RECONNECT_SAAT_HOME=0
}

clr() { clear 2>/dev/null || printf '\033[2J\033[H'; }

header() {
    echo "========================================="
    echo "   ROBLOX AUTO RECONNECT + AUTO RELOG"
    echo "   2 INSTANCE"
    echo "========================================="
}

show_toggle() {
    local val=$1
    if [ "$val" = "1" ]; then echo "ON"; else echo "OFF"; fi
}

show_current_config() {
    echo ""
    echo "  URL    : ${URL:-[belum diisi]}"
    echo "  Relog  : ${RELOG_SETIAP_JAM} jam $([ "$RELOG_SETIAP_JAM" = "0" ] && echo '(OFF)' || echo '(ON)')"
    echo "  Reconnect otomatis : $(show_toggle $RECONNECT_OTOMATIS)"
    echo "  Restart kalau crash: $(show_toggle $RESTART_KALAU_CRASH)"
    echo "  Reconnect saat home: $(show_toggle $RECONNECT_SAAT_HOME)"
    echo ""
}

wizard_setup() {
    clr
    header
    echo ""
    echo "  Halo! Config belum ada, mari setup dulu."
    echo ""

    while true; do
        echo "  Paste link private server Roblox kamu:"
        printf "  > "
        read -r URL
        if [ -n "$URL" ]; then
            break
        fi
        echo "  URL tidak boleh kosong!"
        echo ""
    done

    echo ""
    echo "  Relog otomatis setiap berapa jam? (0=mati, default: 1)"
    printf "  > "
    read -r INPUT_RELOG
    if [[ "$INPUT_RELOG" =~ ^[0-9]+$ ]]; then
        RELOG_SETIAP_JAM=$INPUT_RELOG
    else
        RELOG_SETIAP_JAM=1
    fi

    echo ""
    echo "  Reconnect otomatis saat DC? (1=ON / 0=OFF, default: 1)"
    printf "  > "
    read -r INPUT_RC
    if [ "$INPUT_RC" = "0" ]; then RECONNECT_OTOMATIS=0; else RECONNECT_OTOMATIS=1; fi

    echo ""
    echo "  Restart otomatis kalau Roblox crash? (1=ON / 0=OFF, default: 1)"
    printf "  > "
    read -r INPUT_CR
    if [ "$INPUT_CR" = "0" ]; then RESTART_KALAU_CRASH=0; else RESTART_KALAU_CRASH=1; fi

    echo ""
    echo "  Reconnect saat app di-minimize/home? (1=ON / 0=OFF, default: 0)"
    printf "  > "
    read -r INPUT_RH
    if [ "$INPUT_RH" = "1" ]; then RECONNECT_SAAT_HOME=1; else RECONNECT_SAAT_HOME=0; fi

    save_config

    echo ""
    echo "  Config tersimpan!"
    echo ""
    sleep 1
}

menu_utama() {
    while true; do
        clr
        header
        show_current_config
        echo "  Mau ngapain?"
        echo ""
        echo "  1) Langsung jalanin"
        echo "  2) Ganti URL private server"
        echo "  3) Ubah setting"
        echo "  4) Keluar"
        echo ""
        printf "  Pilih (1-4): "
        read -r PILIHAN

        case $PILIHAN in
            1) return 0 ;;
            2) menu_ganti_url ;;
            3) menu_edit_setting ;;
            4) echo ""; echo "  Sampai jumpa!"; echo ""; exit 0 ;;
            *) echo "  Pilih angka 1-4"; sleep 1 ;;
        esac
    done
}

menu_ganti_url() {
    clr
    header
    echo ""
    echo "  URL saat ini:"
    echo "  ${URL:-[kosong]}"
    echo ""
    echo "  Paste URL baru (Enter untuk batal):"
    printf "  > "
    read -r NEW_URL
    if [ -n "$NEW_URL" ]; then
        URL="$NEW_URL"
        save_config
        echo ""
        echo "  URL diperbarui!"
    else
        echo ""
        echo "  Dibatalkan."
    fi
    sleep 1
}

menu_edit_setting() {
    while true; do
        clr
        header
        echo ""
        echo "  1) Relog otomatis : ${RELOG_SETIAP_JAM} jam $([ "$RELOG_SETIAP_JAM" = "0" ] && echo '(OFF)' || echo '(ON)')"
        echo "  2) Reconnect otomatis  : $(show_toggle $RECONNECT_OTOMATIS)"
        echo "  3) Restart kalau crash : $(show_toggle $RESTART_KALAU_CRASH)"
        echo "  4) Reconnect saat home : $(show_toggle $RECONNECT_SAAT_HOME)"
        echo "  5) Kembali"
        echo ""
        printf "  Pilih (1-5): "
        read -r PILIHAN

        case $PILIHAN in
            1)
                echo ""
                echo "  Relog setiap berapa jam? (0=matikan):"
                printf "  > "
                read -r V
                if [[ "$V" =~ ^[0-9]+$ ]]; then RELOG_SETIAP_JAM=$V; save_config; echo "  Disimpan!"; else echo "  Masukkan angka!"; fi
                sleep 1 ;;
            2)
                echo ""
                echo "  Reconnect otomatis (1=ON / 0=OFF):"
                printf "  > "
                read -r V
                if [ "$V" = "0" ] || [ "$V" = "1" ]; then RECONNECT_OTOMATIS=$V; save_config; echo "  Disimpan!"; else echo "  Masukkan 0 atau 1!"; fi
                sleep 1 ;;
            3)
                echo ""
                echo "  Restart kalau crash (1=ON / 0=OFF):"
                printf "  > "
                read -r V
                if [ "$V" = "0" ] || [ "$V" = "1" ]; then RESTART_KALAU_CRASH=$V; save_config; echo "  Disimpan!"; else echo "  Masukkan 0 atau 1!"; fi
                sleep 1 ;;
            4)
                echo ""
                echo "  Reconnect saat home (1=ON / 0=OFF):"
                printf "  > "
                read -r V
                if [ "$V" = "0" ] || [ "$V" = "1" ]; then RECONNECT_SAAT_HOME=$V; save_config; echo "  Disimpan!"; else echo "  Masukkan 0 atau 1!"; fi
                sleep 1 ;;
            5) return ;;
            *) echo "  Pilih 1-5"; sleep 1 ;;
        esac
    done
}

log() {
    echo "[$(date +%H:%M:%S)] $1" | tee -a "$LOG_FILE"
}

join_private_server() {
    local PKG=$1
    local FILE_RC=$2
    log "[$PKG] Join private server..."
    echo "1" > "$FILE_RC"
    am force-stop "$PKG"
    sleep 4
    am start -a android.intent.action.VIEW -d "$URL" "$PKG"
    log "[$PKG] Launched"
    if [ "$PKG" = "$PKG1" ]; then
        echo "$(date +%s)" > "$FILE_LAST_RELOG1"
    else
        echo "$(date +%s)" > "$FILE_LAST_RELOG2"
    fi
}

wait_for_ingame() {
    local PKG=$1
    local FILE_RC=$2
    log "[$PKG] Menunggu INGAME (max 90s)..."
    local FOUND=0

    while read -r line; do
        if echo "$line" | grep -qi "Connection accepted from"; then
            IP=$(echo "$line" | grep -oE "([0-9]{1,3}\.){3}[0-9]{1,3}" | head -1)
            log "[$PKG] INGAME! IP: $IP"
            FOUND=1
            termux-vibrate -d 300 2>/dev/null
            break
        fi
    done < <(timeout 90 logcat -v time 2>/dev/null | grep --line-buffered -i "Connection accepted from")

    if [ "$FOUND" -eq 0 ]; then
        log "[$PKG] Timeout - retry..."
        sleep 3
        am force-stop "$PKG"
        sleep 3
        am start -a android.intent.action.VIEW -d "$URL" "$PKG"

        while read -r line; do
            if echo "$line" | grep -qi "Connection accepted from"; then
                IP=$(echo "$line" | grep -oE "([0-9]{1,3}\.){3}[0-9]{1,3}" | head -1)
                log "[$PKG] INGAME! IP: $IP"
                FOUND=1
                termux-vibrate -d 300 2>/dev/null
                break
            fi
        done < <(timeout 90 logcat -v time 2>/dev/null | grep --line-buffered -i "Connection accepted from")

        [ "$FOUND" -eq 0 ] && log "[$PKG] Retry timeout - lanjut monitoring..."
    fi

    echo "0" > "$FILE_RC"
}

monitor_disconnect() {
    local PKG=$1
    local FILE_RC=$2
    local FILE_BG=$3
    local FILE_LR=$4
    local FILE_LRC=$5

    log "[$PKG] Monitor DC aktif (PID: $$)"
    echo "0" > "$FILE_BG"

    while read -r line; do

        if echo "$line" | grep -qi "foregroundActivities=false" && echo "$line" | grep -q "$PKG"; then
            echo "1" > "$FILE_BG"
            log "[$PKG] App masuk background"
            continue
        fi

        if echo "$line" | grep -qi "foregroundActivities=true" && echo "$line" | grep -q "$PKG"; then
            sleep 5
            echo "0" > "$FILE_BG"
            log "[$PKG] App kembali foreground"
            continue
        fi

        DC_DETECTED=0
        DC_REASON=""

        if echo "$line" | grep -qi "Sending disconnect with reason"; then
            DC_DETECTED=1; DC_REASON="Sending disconnect"
        fi
        if echo "$line" | grep -qi "Connection lost" && ! echo "$line" | grep -qi "Connection lost:"; then
            DC_DETECTED=1; DC_REASON="Connection lost"
        fi
        if echo "$line" | grep -qi "Lost connection with reason"; then
            DC_DETECTED=1; DC_REASON="Lost connection"
        fi
        if echo "$line" | grep -qi "Disconnected from server for reason"; then
            DC_DETECTED=1; DC_REASON="Disconnected from server"
        fi

        if [ "$DC_DETECTED" -eq 1 ]; then
            [ "$RECONNECT_OTOMATIS" = "0" ] && continue

            RECONNECTING=$(cat "$FILE_RC")
            [ "$RECONNECTING" = "1" ] && { log "[$PKG] Sedang reconnect - skip"; continue; }

            BG=$(cat "$FILE_BG")
            if [ "$BG" = "1" ]; then
                if [ "$RECONNECT_SAAT_HOME" = "0" ]; then
                    log "[$PKG] DC di background - skip"
                    continue
                fi
            fi

            NOW=$(date +%s)
            LAST=$(cat "$FILE_LRC")
            DIFF=$((NOW - LAST))
            if [ "$DIFF" -lt "$RECONNECT_COOLDOWN" ]; then
                log "[$PKG] Cooldown ($DIFF/$RECONNECT_COOLDOWN s) - skip"
                continue
            fi

            log "[$PKG] DC! Reason: $DC_REASON"
            echo "$NOW" > "$FILE_LRC"
            sleep 5
            join_private_server "$PKG" "$FILE_RC"
            wait_for_ingame "$PKG" "$FILE_RC"
        fi

    done < <(logcat -v time 2>/dev/null | grep --line-buffered -iE \
        "Sending disconnect with reason|Connection lost|Lost connection with reason|Disconnected from server for reason|foregroundActivities=")
}

start_monitor() {
    local PKG=$1
    local FILE_RC=$2
    local FILE_BG=$3
    local FILE_LR=$4
    local FILE_LRC=$5

    if [ "$PKG" = "$PKG1" ]; then
        kill "$MONITOR_PID1" 2>/dev/null
    else
        kill "$MONITOR_PID2" 2>/dev/null
    fi

    sleep 1
    logcat -c
    sleep 1
    monitor_disconnect "$PKG" "$FILE_RC" "$FILE_BG" "$FILE_LR" "$FILE_LRC" &

    if [ "$PKG" = "$PKG1" ]; then
        MONITOR_PID1=$!
        log "[$PKG] Monitor started (PID: $MONITOR_PID1)"
    else
        MONITOR_PID2=$!
        log "[$PKG] Monitor started (PID: $MONITOR_PID2)"
    fi
}

check_relog_needed() {
    local FILE_LR=$1
    [ "$RELOG_SETIAP_JAM" = "0" ] && return 1
    local NOW; NOW=$(date +%s)
    local LAST; LAST=$(cat "$FILE_LR")
    local ELAPSED=$((NOW - LAST))
    local RELOG_SECONDS=$((RELOG_SETIAP_JAM * 3600))
    [ "$ELAPSED" -ge "$RELOG_SECONDS" ]
}

cleanup() {
    log "Script dihentikan."
    kill "$MONITOR_PID1" 2>/dev/null
    kill "$MONITOR_PID2" 2>/dev/null
    rm -rf "$STATE_DIR"
    exit 0
}
trap cleanup INT TERM

if [ "$(id -u)" != "0" ]; then
    echo "Minta akses root..."
    exec su -c "$0"
fi

default_config
load_config

if [ -z "$URL" ] && [ ! -f "$CONFIG_FILE" ]; then
    wizard_setup
    load_config
else
    menu_utama
    load_config
fi

mkdir -p "$STATE_DIR"
echo "0" > "$FILE_LAST_RECONNECT1"
echo "0" > "$FILE_LAST_RECONNECT2"
echo "0" > "$FILE_IN_BACKGROUND1"
echo "0" > "$FILE_IN_BACKGROUND2"
echo "$(date +%s)" > "$FILE_LAST_RELOG1"
echo "$(date +%s)" > "$FILE_LAST_RELOG2"
echo "0" > "$FILE_RECONNECTING1"
echo "0" > "$FILE_RECONNECTING2"

clr
echo "========================================="
echo "   ROBLOX AUTO RECONNECT + AUTO RELOG"
echo "   2 INSTANCE"
echo "========================================="
log "URL              : $URL"
log "Relog            : setiap ${RELOG_SETIAP_JAM} jam"
log "Reconnect        : $(show_toggle $RECONNECT_OTOMATIS)"
log "Restart crash    : $(show_toggle $RESTART_KALAU_CRASH)"
log "Reconnect@home   : $(show_toggle $RECONNECT_SAAT_HOME)"
echo "========================================="

join_private_server "$PKG1" "$FILE_RECONNECTING1"
wait_for_ingame "$PKG1" "$FILE_RECONNECTING1"
sleep 5
join_private_server "$PKG2" "$FILE_RECONNECTING2"
wait_for_ingame "$PKG2" "$FILE_RECONNECTING2"

log "Monitoring aktif..."
echo "-----------------------------------------"

start_monitor "$PKG1" "$FILE_RECONNECTING1" "$FILE_IN_BACKGROUND1" "$FILE_LAST_RELOG1" "$FILE_LAST_RECONNECT1"
sleep 2
start_monitor "$PKG2" "$FILE_RECONNECTING2" "$FILE_IN_BACKGROUND2" "$FILE_LAST_RELOG2" "$FILE_LAST_RECONNECT2"

while true; do

    if [ "$RESTART_KALAU_CRASH" = "1" ]; then
        if ! ps -A 2>/dev/null | grep -q "$PKG1" && ! pidof "$PKG1" > /dev/null 2>&1; then
            log "[$PKG1] Crash! Restart..."
            sleep 3
            join_private_server "$PKG1" "$FILE_RECONNECTING1"
            wait_for_ingame "$PKG1" "$FILE_RECONNECTING1"
            start_monitor "$PKG1" "$FILE_RECONNECTING1" "$FILE_IN_BACKGROUND1" "$FILE_LAST_RELOG1" "$FILE_LAST_RECONNECT1"
        fi

        if ! ps -A 2>/dev/null | grep -q "$PKG2" && ! pidof "$PKG2" > /dev/null 2>&1; then
            log "[$PKG2] Crash! Restart..."
            sleep 3
            join_private_server "$PKG2" "$FILE_RECONNECTING2"
            wait_for_ingame "$PKG2" "$FILE_RECONNECTING2"
            start_monitor "$PKG2" "$FILE_RECONNECTING2" "$FILE_IN_BACKGROUND2" "$FILE_LAST_RELOG2" "$FILE_LAST_RECONNECT2"
        fi
    fi

    if check_relog_needed "$FILE_LAST_RELOG1"; then
        log "[$PKG1] Relog..."
        join_private_server "$PKG1" "$FILE_RECONNECTING1"
        wait_for_ingame "$PKG1" "$FILE_RECONNECTING1"
        start_monitor "$PKG1" "$FILE_RECONNECTING1" "$FILE_IN_BACKGROUND1" "$FILE_LAST_RELOG1" "$FILE_LAST_RECONNECT1"
    fi

    if check_relog_needed "$FILE_LAST_RELOG2"; then
        log "[$PKG2] Relog..."
        join_private_server "$PKG2" "$FILE_RECONNECTING2"
        wait_for_ingame "$PKG2" "$FILE_RECONNECTING2"
        start_monitor "$PKG2" "$FILE_RECONNECTING2" "$FILE_IN_BACKGROUND2" "$FILE_LAST_RELOG2" "$FILE_LAST_RECONNECT2"
    fi

    NOW=$(date +%s)
    if [ $((NOW - LAST_VERBOSE)) -ge "$VERBOSE_INTERVAL" ]; then
        log "Roblox 1 & 2 running"
        LAST_VERBOSE=$NOW
    fi

    sleep "$CHECK_INTERVAL"
done
