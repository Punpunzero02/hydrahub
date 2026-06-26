#!/data/data/com.termux/files/usr/bin/bash

PKG1="com.roblox.nodey"
PKG2="com.roblox.nodez"
CHECK_INTERVAL=10
LOG_FILE="/storage/emulated/0/roblox_reconnect.log"
CONFIG_FILE="/data/local/tmp/roblox_config.cfg"
STATE_DIR="/data/local/tmp/rbx_state"

JOIN_TIMEOUT=70
MONITOR_PID1=""
MONITOR_PID2=""
TIMEOUT_PID1=""
TIMEOUT_PID2=""
LAST_VERBOSE=0
VERBOSE_INTERVAL=60

load_config() {
    [ -f "$CONFIG_FILE" ] && source "$CONFIG_FILE"
}

save_config() {
    cat > "$CONFIG_FILE" <<EOF
URL="$URL"
RELOG_SETIAP_JAM=$RELOG_SETIAP_JAM
RESTART_KALAU_CRASH=$RESTART_KALAU_CRASH
RECONNECT_SAAT_HOME=$RECONNECT_SAAT_HOME
MODE=$MODE
EOF
}

default_config() {
    URL=""
    RELOG_SETIAP_JAM=1
    RESTART_KALAU_CRASH=1
    RECONNECT_SAAT_HOME=0
    MODE="stayps"
}

clr() { clear 2>/dev/null || printf '\033[2J\033[H'; }

header() {
    echo "========================================="
    echo "   ROBLOX AUTO RECONNECT + AUTO RELOG"
    echo "   2 INSTANCE"
    echo "========================================="
}

show_toggle() {
    [ "$1" = "1" ] && echo "ON" || echo "OFF"
}

show_current_config() {
    echo ""
    echo "  URL    : ${URL:-[belum diisi]}"
    echo "  Relog  : ${RELOG_SETIAP_JAM} jam $([ "$RELOG_SETIAP_JAM" = "0" ] && echo '(OFF)' || echo '(ON)')"
    echo "  Restart crash    : $(show_toggle $RESTART_KALAU_CRASH)"
    echo "  Reconnect@home   : $(show_toggle $RECONNECT_SAAT_HOME)"
    echo "  Mode             : $MODE"
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
        [ -n "$URL" ] && break
        echo "  URL tidak boleh kosong!"
    done
    echo ""
    echo "  Relog otomatis setiap berapa jam? (0=mati, default: 1)"
    printf "  > "
    read -r INPUT_RELOG
    [[ "$INPUT_RELOG" =~ ^[0-9]+$ ]] && RELOG_SETIAP_JAM=$INPUT_RELOG || RELOG_SETIAP_JAM=1
    echo ""
    echo "  Restart otomatis kalau Roblox crash? (1=ON / 0=OFF, default: 1)"
    printf "  > "
    read -r INPUT_CR
    [ "$INPUT_CR" = "0" ] && RESTART_KALAU_CRASH=0 || RESTART_KALAU_CRASH=1
    echo ""
    echo "  Reconnect saat app di-minimize/home? (1=ON / 0=OFF, default: 0)"
    printf "  > "
    read -r INPUT_RH
    [ "$INPUT_RH" = "1" ] && RECONNECT_SAAT_HOME=1 || RECONNECT_SAAT_HOME=0
    echo ""
    echo "  Mode reconnect:"
    echo "  1) Stay PS - apapun yg terjadi selalu rejoin ke PS"
    echo "  2) Normal  - detect DC dulu, baru reconnect"
    printf "  > "
    read -r INPUT_MODE
    [ "$INPUT_MODE" = "2" ] && MODE="normal" || MODE="stayps"
    save_config
    echo ""
    echo "  Config tersimpan!"
    sleep 1
}

menu_utama() {
    while true; do
        clr
        header
        show_current_config
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
            4) echo ""; echo "  Sampai jumpa!"; exit 0 ;;
            *) echo "  Pilih angka 1-4"; sleep 1 ;;
        esac
    done
}

menu_ganti_url() {
    clr; header
    echo ""
    echo "  URL saat ini: ${URL:-[kosong]}"
    echo ""
    echo "  Paste URL baru (Enter untuk batal):"
    printf "  > "
    read -r NEW_URL
    if [ -n "$NEW_URL" ]; then
        URL="$NEW_URL"; save_config; echo "  URL diperbarui!"
    else
        echo "  Dibatalkan."
    fi
    sleep 1
}

menu_edit_setting() {
    while true; do
        clr; header
        echo ""
        echo "  1) Relog otomatis : ${RELOG_SETIAP_JAM} jam $([ "$RELOG_SETIAP_JAM" = "0" ] && echo '(OFF)' || echo '(ON)')"
        echo "  2) Restart kalau crash : $(show_toggle $RESTART_KALAU_CRASH)"
        echo "  3) Reconnect saat home : $(show_toggle $RECONNECT_SAAT_HOME)"
        echo "  4) Mode : $MODE"
        echo "  5) Kembali"
        echo ""
        printf "  Pilih (1-5): "
        read -r PILIHAN
        case $PILIHAN in
            1)
                echo ""; echo "  Relog setiap berapa jam? (0=matikan):"; printf "  > "; read -r V
                [[ "$V" =~ ^[0-9]+$ ]] && RELOG_SETIAP_JAM=$V && save_config && echo "  Disimpan!" || echo "  Masukkan angka!"
                sleep 1 ;;
            2)
                echo ""; echo "  Restart kalau crash (1=ON / 0=OFF):"; printf "  > "; read -r V
                { [ "$V" = "0" ] || [ "$V" = "1" ]; } && RESTART_KALAU_CRASH=$V && save_config && echo "  Disimpan!" || echo "  Masukkan 0 atau 1!"
                sleep 1 ;;
            3)
                echo ""; echo "  Reconnect saat home (1=ON / 0=OFF):"; printf "  > "; read -r V
                { [ "$V" = "0" ] || [ "$V" = "1" ]; } && RECONNECT_SAAT_HOME=$V && save_config && echo "  Disimpan!" || echo "  Masukkan 0 atau 1!"
                sleep 1 ;;
            4)
                echo ""; echo "  Mode (stayps/normal):"; printf "  > "; read -r V
                { [ "$V" = "stayps" ] || [ "$V" = "normal" ]; } && MODE=$V && save_config && echo "  Disimpan!" || echo "  Masukkan stayps atau normal!"
                sleep 1 ;;
            5) return ;;
            *) echo "  Pilih 1-5"; sleep 1 ;;
        esac
    done
}

log() {
    echo "[$(date +%H:%M:%S)] $1" | tee -a "$LOG_FILE"
}

update_pid() {
    local PKG=$1 NUM=$2
    local PID=$(su -c "pidof $PKG" 2>/dev/null | awk '{print $1}')
    echo "${PID:-0}" > "$STATE_DIR/pid${NUM}"
}

get_pid() {
    cat "$STATE_DIR/pid${1}" 2>/dev/null || echo "0"
}

get_cpu_ram() {
    local NUM=$1
    local PID=$(get_pid "$NUM")
    [ "$PID" = "0" ] && echo "CPU:? RAM:?" && return
    local CPU=0
    local STAT1=$(cat /proc/$PID/stat 2>/dev/null)
    sleep 1
    local STAT2=$(cat /proc/$PID/stat 2>/dev/null)
    if [ -n "$STAT1" ] && [ -n "$STAT2" ]; then
        local U1=$(echo $STAT1 | awk '{print $14+$15}')
        local U2=$(echo $STAT2 | awk '{print $14+$15}')
        CPU=$(echo "$U2 $U1" | awk '{printf "%.1f", ($1-$2)/1}')
    fi
    local RAM=$(cat /proc/$PID/status 2>/dev/null | grep VmRSS | awk '{print int($2/1024)}')
    echo "CPU:${CPU}% RAM:${RAM:-?}MB"
}

get_ping() {
    local NUM=$1
    local IP=$(cat "$STATE_DIR/server_ip${NUM}" 2>/dev/null)
    [ -z "$IP" ] && echo "MS:?" && return
    local MS=$(ping -c 1 -W 2 "$IP" 2>/dev/null | grep "time=" | grep -oE "time=[0-9.]+" | cut -d= -f2)
    echo "MS:${MS:-?}"
}

get_lag_status() {
    local NUM=$1
    local LAG=$(cat "$STATE_DIR/lag${NUM}" 2>/dev/null || echo 0)
    [ "$LAG" = "1" ] && echo "LAG" || echo "OK"
}

bring_to_foreground() {
    local PKG=$1
    local DELAY=$((RANDOM % 4 + 5))
    sleep "$DELAY"
    su -c "am start -n $PKG/com.roblox.client.ActivityNativeMain" 2>/dev/null
}

join_private_server() {
    local PKG=$1 NUM=$2
    log "[$PKG] Join private server..."
    echo "0" > "$STATE_DIR/ingame${NUM}"
    echo "0" > "$STATE_DIR/joining${NUM}"
    echo "0" > "$STATE_DIR/lag${NUM}"
    am force-stop "$PKG"
    sleep 4
    am start -a android.intent.action.VIEW -d "$URL" "$PKG"
    sleep 2
    update_pid "$PKG" "$NUM"
    local RC=$(cat "$STATE_DIR/rc_count${NUM}" 2>/dev/null || echo 0)
    echo $((RC+1)) > "$STATE_DIR/rc_count${NUM}"
    echo "$(date +%s)" > "$STATE_DIR/last_relog${NUM}"
    log "[$PKG] Launched | RC:$((RC+1))"
}

start_join_timeout() {
    local PKG=$1 NUM=$2
    [ "$NUM" = "1" ] && kill "$TIMEOUT_PID1" 2>/dev/null || kill "$TIMEOUT_PID2" 2>/dev/null
    echo "1" > "$STATE_DIR/joining${NUM}"
    (
        sleep "$JOIN_TIMEOUT"
        local INGAME=$(cat "$STATE_DIR/ingame${NUM}" 2>/dev/null || echo 0)
        local JOINING=$(cat "$STATE_DIR/joining${NUM}" 2>/dev/null || echo 0)
        if [ "$JOINING" = "1" ] && [ "$INGAME" != "1" ]; then
            log "[$PKG] Timeout ${JOIN_TIMEOUT}s - reconnect..."
            local DC=$(cat "$STATE_DIR/dc_count${NUM}" 2>/dev/null || echo 0)
            echo $((DC+1)) > "$STATE_DIR/dc_count${NUM}"
            join_private_server "$PKG" "$NUM"
            start_monitor "$PKG" "$NUM"
        fi
    ) &
    [ "$NUM" = "1" ] && TIMEOUT_PID1=$! || TIMEOUT_PID2=$!
}

monitor_instance() {
    local PKG=$1 NUM=$2
    log "[$PKG] Monitor aktif (PID: $$)"
    echo "0" > "$STATE_DIR/in_background${NUM}"
    echo "0" > "$STATE_DIR/lag${NUM}"
    update_pid "$PKG" "$NUM"
    local CURRENT_PID=$(get_pid "$NUM")

    su -c "logcat --pid=$CURRENT_PID -v time" 2>/dev/null | while read -r line; do

        if echo "$line" | grep -q "Detected application backgrounding"; then
            echo "1" > "$STATE_DIR/in_background${NUM}"
            log "[$PKG] Background"
            if [ "$RECONNECT_SAAT_HOME" = "0" ]; then
                bring_to_foreground "$PKG" &
            fi
            continue
        fi

        if echo "$line" | grep -q "Detected application foregrounding"; then
            echo "0" > "$STATE_DIR/in_background${NUM}"
            log "[$PKG] Foreground"
            continue
        fi

        if echo "$line" | grep -qE "! Joining game|launchGameWithParams"; then
            local IP=$(echo "$line" | grep -oE "([0-9]{1,3}\.){3}[0-9]{1,3}" | head -1)
            [ -n "$IP" ] && echo "$IP" > "$STATE_DIR/server_ip${NUM}"
            log "[$PKG] Join dimulai - timeout ${JOIN_TIMEOUT}s"
            echo "0" > "$STATE_DIR/ingame${NUM}"
            start_join_timeout "$PKG" "$NUM"
            continue
        fi

        if echo "$line" | grep -q "onGameLoaded.*SessionReporterState_GameLoaded"; then
            log "[$PKG] INGAME!"
            echo "1" > "$STATE_DIR/ingame${NUM}"
            echo "0" > "$STATE_DIR/joining${NUM}"
            [ "$NUM" = "1" ] && kill "$TIMEOUT_PID1" 2>/dev/null || kill "$TIMEOUT_PID2" 2>/dev/null
            continue
        fi

        if echo "$line" | grep -q "Davey! duration="; then
            local DUR=$(echo "$line" | grep -oE "duration=[0-9]+" | cut -d= -f2)
            if [ -n "$DUR" ] && [ "$DUR" -gt 500 ]; then
                echo "1" > "$STATE_DIR/lag${NUM}"
            else
                echo "0" > "$STATE_DIR/lag${NUM}"
            fi
            continue
        fi

        if [ "$MODE" = "stayps" ]; then
            if echo "$line" | grep -qE "doTeleport|Lost connection with reason"; then
                log "[$PKG] [STAYPS] DC/Hop detected - force rejoin PS..."
                local DC=$(cat "$STATE_DIR/dc_count${NUM}" 2>/dev/null || echo 0)
                echo $((DC+1)) > "$STATE_DIR/dc_count${NUM}"
                join_private_server "$PKG" "$NUM"
                update_pid "$PKG" "$NUM"
                CURRENT_PID=$(get_pid "$NUM")
                break
            fi
        fi

        if [ "$MODE" = "normal" ]; then
            if echo "$line" | grep -q "Lost connection with reason"; then
                log "[$PKG] [NORMAL] DC detected - tunggu 3s cek doTeleport..."
                echo "WAITING" > "$STATE_DIR/dc_state${NUM}"
                (
                    sleep 3
                    local STATE=$(cat "$STATE_DIR/dc_state${NUM}" 2>/dev/null)
                    if [ "$STATE" = "WAITING" ]; then
                        log "[$PKG] [NORMAL] Tidak ada doTeleport - reconnect ke PS..."
                        local DC=$(cat "$STATE_DIR/dc_count${NUM}" 2>/dev/null || echo 0)
                        echo $((DC+1)) > "$STATE_DIR/dc_count${NUM}"
                        echo "DONE" > "$STATE_DIR/dc_state${NUM}"
                        join_private_server "$PKG" "$NUM"
                        start_monitor "$PKG" "$NUM"
                    fi
                ) &
                continue
            fi

            if echo "$line" | grep -q "doTeleport"; then
                local STATE=$(cat "$STATE_DIR/dc_state${NUM}" 2>/dev/null)
                if [ "$STATE" = "WAITING" ]; then
                    log "[$PKG] [NORMAL] doTeleport detected - Roblox handle sendiri, pantau 70s..."
                    echo "DONE" > "$STATE_DIR/dc_state${NUM}"
                fi
                continue
            fi
        fi

        if echo "$line" | grep -q "System.exit called"; then
            log "[$PKG] Crash!"
            echo "0" > "$STATE_DIR/ingame${NUM}"
            echo "0" > "$STATE_DIR/joining${NUM}"
            if [ "$RESTART_KALAU_CRASH" = "1" ]; then
                local DC=$(cat "$STATE_DIR/dc_count${NUM}" 2>/dev/null || echo 0)
                echo $((DC+1)) > "$STATE_DIR/dc_count${NUM}"
                sleep 3
                join_private_server "$PKG" "$NUM"
                update_pid "$PKG" "$NUM"
                CURRENT_PID=$(get_pid "$NUM")
                break
            fi
        fi

    done

    log "[$PKG] Monitor ended - restart..."
    sleep 2
    monitor_instance "$PKG" "$NUM" &
    [ "$NUM" = "1" ] && MONITOR_PID1=$! || MONITOR_PID2=$!
}

start_monitor() {
    local PKG=$1 NUM=$2
    [ "$NUM" = "1" ] && kill "$MONITOR_PID1" 2>/dev/null || kill "$MONITOR_PID2" 2>/dev/null
    sleep 1
    monitor_instance "$PKG" "$NUM" &
    if [ "$NUM" = "1" ]; then
        MONITOR_PID1=$!
        log "[$PKG] Monitor started (PID: $MONITOR_PID1)"
    else
        MONITOR_PID2=$!
        log "[$PKG] Monitor started (PID: $MONITOR_PID2)"
    fi
}

check_relog_needed() {
    local NUM=$1
    [ "$RELOG_SETIAP_JAM" = "0" ] && return 1
    local NOW=$(date +%s)
    local LAST=$(cat "$STATE_DIR/last_relog${NUM}" 2>/dev/null || echo 0)
    [ $((NOW - LAST)) -ge $((RELOG_SETIAP_JAM * 3600)) ]
}

show_status() {
    local NOW=$(date +%H:%M:%S)
    local INGAME1=$(cat "$STATE_DIR/ingame1" 2>/dev/null || echo 0)
    local INGAME2=$(cat "$STATE_DIR/ingame2" 2>/dev/null || echo 0)
    local BG1=$(cat "$STATE_DIR/in_background1" 2>/dev/null || echo 0)
    local BG2=$(cat "$STATE_DIR/in_background2" 2>/dev/null || echo 0)
    local DC1=$(cat "$STATE_DIR/dc_count1" 2>/dev/null || echo 0)
    local DC2=$(cat "$STATE_DIR/dc_count2" 2>/dev/null || echo 0)
    local RC1=$(cat "$STATE_DIR/rc_count1" 2>/dev/null || echo 0)
    local RC2=$(cat "$STATE_DIR/rc_count2" 2>/dev/null || echo 0)
    local STATS1=$(get_cpu_ram "1")
    local STATS2=$(get_cpu_ram "2")
    local PING1=$(get_ping "1")
    local PING2=$(get_ping "2")
    local LAG1=$(get_lag_status "1")
    local LAG2=$(get_lag_status "2")

    local STATUS1="INGAME"
    [ "$INGAME1" != "1" ] && STATUS1="LOADING"
    [ "$BG1" = "1" ] && STATUS1="BACKGROUND"

    local STATUS2="INGAME"
    [ "$INGAME2" != "1" ] && STATUS2="LOADING"
    [ "$BG2" = "1" ] && STATUS2="BACKGROUND"

    echo ""
    echo "========================================="
    echo "  [$NOW] STATUS | MODE: $MODE"
    echo "========================================="
    echo "  PKG1 : $STATUS1 | DC:$DC1 RC:$RC1 | $STATS1 | $PING1 | $LAG1"
    echo "  PKG2 : $STATUS2 | DC:$DC2 RC:$RC2 | $STATS2 | $PING2 | $LAG2"
    echo "========================================="
}

cleanup() {
    log "Script dihentikan."
    kill "$MONITOR_PID1" "$MONITOR_PID2" "$TIMEOUT_PID1" "$TIMEOUT_PID2" 2>/dev/null
    rm -rf "$STATE_DIR"
    exit 0
}
trap cleanup INT TERM

if [ "$(id -u)" != "0" ]; then
    echo "Minta akses root..."
    exec su -c "/data/data/com.termux/files/usr/bin/bash $(realpath $0)"
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
for F in ingame1 ingame2 joining1 joining2 in_background1 in_background2 dc_count1 dc_count2 rc_count1 rc_count2 lag1 lag2 dc_state1 dc_state2; do
    echo "0" > "$STATE_DIR/$F"
done
echo "$(date +%s)" > "$STATE_DIR/last_relog1"
echo "$(date +%s)" > "$STATE_DIR/last_relog2"

clr
echo "========================================="
echo "   ROBLOX AUTO RECONNECT + AUTO RELOG"
echo "   2 INSTANCE | MODE: $MODE"
echo "========================================="
log "URL    : $URL"
log "Relog  : ${RELOG_SETIAP_JAM} jam"
log "Crash  : $(show_toggle $RESTART_KALAU_CRASH)"
log "Home   : $(show_toggle $RECONNECT_SAAT_HOME)"
log "Mode   : $MODE"
log "Timeout: ${JOIN_TIMEOUT}s"
echo "========================================="

join_private_server "$PKG1" "1"
sleep 5
join_private_server "$PKG2" "2"
sleep 3

start_monitor "$PKG1" "1"
sleep 2
start_monitor "$PKG2" "2"

start_join_timeout "$PKG1" "1"
sleep 2
start_join_timeout "$PKG2" "2"

log "Monitoring aktif..."

while true; do
    if check_relog_needed "1"; then
        log "[$PKG1] Relog..."
        join_private_server "$PKG1" "1"
        start_monitor "$PKG1" "1"
        start_join_timeout "$PKG1" "1"
    fi

    if check_relog_needed "2"; then
        log "[$PKG2] Relog..."
        join_private_server "$PKG2" "2"
        start_monitor "$PKG2" "2"
        start_join_timeout "$PKG2" "2"
    fi

    local NOW=$(date +%s)
    if [ $((NOW - LAST_VERBOSE)) -ge "$VERBOSE_INTERVAL" ]; then
        show_status
        LAST_VERBOSE=$NOW
    fi

    sleep "$CHECK_INTERVAL"
done
