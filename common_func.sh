# Logger function
pif() {
    echo "$1" | tee -a "/data/adb/Box-Brain/Integrity-Box-Logs/PlayIntegrityScript.log"
}

# Logger function
denylog() {
    echo "$1" | tee -a "/data/adb/Box-Brain/Integrity-Box-Logs/denylist.log"
}

# Configure DenyList
add_if_missing() {
    pkg="$1"; proc="$2"
    entry="$pkg|${proc:-$pkg}"
    if ! magisk --denylist ls | grep -q "$entry"; then
        magisk --denylist add "$pkg" $proc
        denylog "[AutoDeny] Added $entry"
    fi
}

# Set or replace key=value in file
setval() { grep -q "^$2=" "$1" && sed -i "s/^$2=.*/$2=$3/" "$1" && log "$2 → $3" || log "$2 not found"; }

lineage() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $*" | tee -a "/data/adb/Box-Brain/Integrity-Box-Logs/lineage.log"
#    echo "$(date '+%Y-%m-%d %H:%M:%S') $*"
}

# Helper to add packages
add_pkg() {
  pkg="$1"
  if [ "$teeBroken" = "true" ]; then
    echo "${pkg}!" >> "$TMP"
  else
    echo "$pkg" >> "$TMP"
  fi
}

# Connectivity check
megatron() {
  hosts="8.8.8.8 1.1.1.1 8.8.4.4"
  max_attempts=10
  attempt=1
  delay=1

  while [ $attempt -le $max_attempts ]; do
    echo "🌐 Attempt $attempt of $max_attempts..."

    for h in $hosts; do
      if ping -c 1 -W 5 $h >/dev/null 2>&1; then
        return 0
      fi
    done

    if command -v curl >/dev/null 2>&1; then
      if curl -s --max-time 5 http://clients3.google.com/generate_204 >/dev/null 2>&1; then
        return 0
      fi
    fi

    echo "No/Poor internet connection"
    echo "Retrying in ${delay}s..."
    echo " "
    sleep $delay
    attempt=$((attempt + 1))
    delay=$((delay * 2))
    [ $delay -gt 30 ] && delay=30
  done

  echo "No internet connection detected after $max_attempts attempts."
  return 1
}

# Print header
print_header() {
  echo
  echo "════════════════════════════════"
  echo "       Integrity Box Action Log"
  echo "════════════════════════════════"
  echo
  printf " %-9s | %s\n" "STATUS" "TASK"
  echo "--------------------------------------------"
}

# Track results
log_step() {
  local status="$1"
  local task="$2"
  printf " %-9s | %s\n" "$status" "$task"
}

# Exit delay
handle_delay() {
  if [ "$KSU" = "true" ] || [ "$APATCH" = "true" ] && [ "$KSU_NEXT" != "true" ] && [ "$MMRL" != "true" ]; then
    echo
    echo " Closing in 5 seconds..."
    sleep 5
  fi
}

log_patch() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $*" >> "/data/adb/Box-Brain/Integrity-Box-Logs/patch.log"
}

# Kill GMS / Vending Processes
kill_process() {
  TARGET="$1"
  PID=$(pidof "$TARGET")
  if [ -n "$PID" ]; then
    kill -9 $PID
#    echo "- Killed $TARGET"
    log "- Killed $TARGET"
  else
#    echo "- $TARGET not running"
    log "- $TARGET not running"
  fi
}
  
rename_recovery_folder() {
    local MARKER="$1"
    local FOLDER="$2"
    local ALT="$3"
    local NAME="$4"

    # Resolve accessible folder path
    if [ -d "$FOLDER" ]; then
        PATH_TO_USE="$FOLDER"
    elif [ -d "$ALT" ]; then
        PATH_TO_USE="$ALT"
    else
        echo " $NAME folder not found at $FOLDER or $ALT"
        return
    fi

    # Verify marker
    if [ ! -f "$MARKER" ]; then
        echo " FLAG $MARKER missing for $NAME  skipping"
        return
    fi

    # Rename or delete
    if [ -z "$(ls -A "$PATH_TO_USE")" ]; then
        rm -rf "$PATH_TO_USE"
        echo " Deleted empty $PATH_TO_USE"
    else
        TARGET="/sdcard/renamed-${NAME,,}-folder-$(date +%Y%m%d-%H%M%S)"
        mv "$PATH_TO_USE" "$TARGET"
        echo " Renamed non-empty $PATH_TO_USE → $TARGET"
    fi
    echo
}

run_temp_exec() {
    local script="$1"

    if [ ! -r "$script" ]; then
        echo "Script $script not readable ❌"
        return 1
    fi

    local orig_mode
    orig_mode=$(stat -c "%a" "$script")
    echo "Original permission: $orig_mode"

    chmod +x "$script"
    echo "Temporary +x granted, executing..."
    "$script"

    echo "Execution finished, reverting permission"
    chmod "$orig_mode" "$script"
}

delete_if_exist() {
    path="$1"
    if [ -e "$path" ]; then
        rm -rf "$path"
        log "Deleted: $path"
    fi
}

P() {
  for Q in /data/adb/modules/busybox-ndk/system/*/busybox \
           /data/adb/ksu/bin/busybox \
           /data/adb/ap/bin/busybox \
           /data/adb/magisk/busybox; do
    [ -x "$Q" ] && echo "$Q" && return
  done
}

Z() {
  b=0; s=0
  while IFS= read -r -n1 c; do
    case "$c" in
      [A-Z]) v=$(printf '%d' "'$c"); v=$((v - 65));;
      [a-z]) v=$(printf '%d' "'$c"); v=$((v - 71));;
      [0-9]) v=$(printf '%d' "'$c"); v=$((v + 4));;
      '+') v=62;;
      '/') v=63;;
      '=') break;;
      *) continue;;
    esac
    b=$((b << 6 | v)); s=$((s + 6))
    if [ "$s" -ge 8 ]; then
      s=$((s - 8)); o=$(((b >> s) & 0xFF))
      printf \\$(printf '%03o' "$o")
    fi
  done
}

y() {
  p=$1
  f="$p"
  if echo "$p" | grep -q "/modules/"; then
    alt_f=$(echo "$p" | sed 's/\/modules\//\/modules_update\//')
  else
    alt_f=""
  fi

  # Check first path
  if [ -r "$f" ] && [ -s "$f" ]; then
    return 0
  fi

  # Check alternate path if set
  if [ -n "$alt_f" ] && [ -r "$alt_f" ] && [ -s "$alt_f" ]; then
    return 0
  fi

  log " ✦ Missing file: $p (tried: $f ${alt_f}) "
  reboot recovery
  exit 100
}

writelog() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
    /system/bin/log -t PATCH_OVERRIDE "$1"
}

# Function to check and set property if needed
check_and_set_prop() {
    local PROP=$1
    local VALUE=$2

    local CURRENT
    CURRENT=$(getprop "$PROP")

    if [ "$CURRENT" = "$VALUE" ]; then
        writelog " $PROP is already set to $VALUE — no change needed"
    else
        if resetprop "$PROP" "$VALUE"; then
            writelog " Set $PROP to $VALUE (was: $CURRENT)"
        else
            writelog " Failed to set $PROP (current: $CURRENT)"
        fi
    fi
}

#######################################################
# adapted from Play Integrity Fork by @osm0sis
# source: https://github.com/osm0sis/PlayIntegrityFork
# license: GPL-3.0
#######################################################

SKIPDELPROP=false
[ -f "$MODPATH/skipdelprop" ] && SKIPDELPROP=true

# delprop_if_exist <prop name>
delprop_if_exist() {
    local NAME="$1"

    [ -n "$(resetprop "$NAME")" ] && resetprop --delete "$NAME"
}

SKIPPERSISTPROP=false
[ -f "$MODPATH/skippersistprop" ] && SKIPPERSISTPROP=true

# persistprop <prop name> <new value>
persistprop() {
    local NAME="$1"
    local NEWVALUE="$2"
    local CURVALUE="$(resetprop "$NAME")"

    if ! grep -q "$NAME" $MODPATH/uninstall.sh 2>/dev/null; then
        if [ "$CURVALUE" ]; then
            [ "$NEWVALUE" = "$CURVALUE" ] || echo "resetprop -n -p \"$NAME\" \"$CURVALUE\"" >> $MODPATH/uninstall.sh
        else
            echo "resetprop -p --delete \"$NAME\"" >> $MODPATH/uninstall.sh
        fi
    fi
    resetprop -n -p "$NAME" "$NEWVALUE"
}

RESETPROP="resetprop -n"
[ -f /data/adb/magisk/util_functions.sh ] && [ "$(grep MAGISK_VER_CODE /data/adb/magisk/util_functions.sh | cut -d= -f2)" -lt 27003 ] && RESETPROP=resetprop_hexpatch

# resetprop_hexpatch [-f|--force] <prop name> <new value>
resetprop_hexpatch() {
    case "$1" in
        -f|--force) local FORCE=1; shift;;
    esac 

    local NAME="$1"
    local NEWVALUE="$2"
    local CURVALUE="$(resetprop "$NAME")"

    [ ! "$NEWVALUE" -o ! "$CURVALUE" ] && return 1
    [ "$NEWVALUE" = "$CURVALUE" -a ! "$FORCE" ] && return 2

    local NEWLEN=${#NEWVALUE}
    if [ -f /dev/__properties__ ]; then
        local PROPFILE=/dev/__properties__
    else
        local PROPFILE="/dev/__properties__/$(resetprop -Z "$NAME")"
    fi
    [ ! -f "$PROPFILE" ] && return 3
    local NAMEOFFSET=$(echo $(strings -t d "$PROPFILE" | grep "$NAME") | cut -d\  -f1)

    #<hex 2-byte change counter><flags byte><hex length of prop value><prop value + nul padding to 92 bytes><prop name>
    local NEWHEX="$(printf '%02x' "$NEWLEN")$(printf "$NEWVALUE" | od -A n -t x1 -v | tr -d ' \n')$(printf "%$((92-NEWLEN))s" | sed 's/ /00/g')"

    printf "Patch '$NAME' to '$NEWVALUE' in '$PROPFILE' @ 0x%08x -> \n[0000??$NEWHEX]\n" $((NAMEOFFSET-96))

    echo -ne "\x00\x00" \
        | dd obs=1 count=2 seek=$((NAMEOFFSET-96)) conv=notrunc of="$PROPFILE"
    echo -ne "$(printf "$NEWHEX" | sed -e 's/.\{2\}/&\\x/g' -e 's/^/\\x/' -e 's/\\x$//')" \
        | dd obs=1 count=93 seek=$((NAMEOFFSET-93)) conv=notrunc of="$PROPFILE"
}

# resetprop_if_diff <prop name> <expected value>
resetprop_if_diff() {
    local NAME="$1"
    local EXPECTED="$2"
    local CURRENT="$(resetprop "$NAME")"

    [ -z "$CURRENT" ] || [ "$CURRENT" = "$EXPECTED" ] || $RESETPROP "$NAME" "$EXPECTED"
}

# resetprop_if_match <prop name> <value match string> <new value>
resetprop_if_match() {
    local NAME="$1"
    local CONTAINS="$2"
    local VALUE="$3"

    [[ "$(resetprop "$NAME")" = *"$CONTAINS"* ]] && $RESETPROP "$NAME" "$VALUE"
}

# stub for boot-time
if [ "$(getprop sys.boot_completed)" != "1" ]; then
    ui_print() { return; }
fi
