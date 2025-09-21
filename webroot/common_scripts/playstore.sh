MODSDIR="/data/adb/modules"
logdir="/data/adb/Box-Brain/Integrity-Box-Logs"
logfile="$logdir/playstore.log"
apkdir="/data/adb/Box-Brain"
apkfile="$apkdir/playstore.apk"
backupdir="/sdcard/Download/PlayStore"
splitsdir="$backupdir/splits"
url="https://d.apkpure.net/b/APK/com.android.vending?versionCode=84402800"
expected_hash="522ca1f7b609f26381114a0ee1773d2d796df3e35aca9e72a00262730738b226"
max_retries=3

mkdir -p "$logdir" "$apkdir" "$backupdir" "$splitsdir"
rm -rf "$apkdir/downgrade"

echo "
⠀⣠⣶⣿⣿⣶⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣤⣄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⣾⣿⣿⣿⣿⡆⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠹⢿⣿⣿⡿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿⣿⡏⢀⣀⡀⠀⠀⠀⠀⠀
⠀⠀⣠⣤⣦⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠛⠿⣟⣋⣼⣽⣾⣽⣦⡀⠀⠀⠀
⢀⣼⣿⣷⣾⡽⡄⠀⠀⠀⠀⠀⠀⠀⣴⣶⣶⣿⣿⣿⡿⢿⣟⣽⣾⣿⣿⣦⠀⠀
⣸⣿⣿⣾⣿⣿⣮⣤⣤⣤⣤⡀⠀⠀⠻⣿⡯⠽⠿⠛⠛⠉⠉⢿⣿⣿⣿⣿⣷⡀
⣿⣿⢻⣿⣿⣿⣛⡿⠿⠟⠛⠁⣀⣠⣤⣤⣶⣶⣶⣶⣷⣶⠀⠀⠻⣿⣿⣿⣿⣇
⢻⣿⡆⢿⣿⣿⣿⣿⣤⣶⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⠿⠟⠀⣠⣶⣿⣿⣿⣿⡟
⠈⠛⠃⠈⢿⣿⣿⣿⣿⣿⣿⠿⠟⠛⠋⠉⠁⠀⠀⠀⠀⣠⣾⣿⣿⣿⠟⠋⠁⠀
⠀⠀⠀⠀⠀⠙⢿⣿⣿⡏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣴⣿⣿⣿⠟⠁⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⢸⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⣿⠋⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⠁⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠸⣿⣿⠇⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⣼⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠻⣿⡿⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
"

# lockfile guard
LOCK="/data/adb/Box-Brain/.playstore.lock"
if [ -f "$LOCK" ]; then
  printf "[%s] Another instance already running. Exiting.\n" "$(date '+%H:%M:%S')" >> "$logfile"
  exit 0
fi
touch "$LOCK"
trap 'rm -f "$LOCK"' EXIT

log() {
  printf "[%s] %s\n" "$(date '+%H:%M:%S')" "$1" >> "$logfile"
  echo "$1"
}

# locate BusyBox
shockwave() {
  for p in \
    /data/adb/modules/busybox-ndk/system/*/busybox \
    /data/adb/ksu/bin/busybox \
    /data/adb/ap/bin/busybox \
    /data/adb/magisk/busybox \
    /system/bin/busybox \
    /system/xbin/busybox; do
    [ -x "$p" ] && { printf '%s' "$p"; return 0; }
  done
  return 1
}

# internet check
internet() {
  local hosts="8.8.8.8 1.1.1.1 8.8.4.4"
  local max_attempts=5
  local attempt=1

  while [ "$attempt" -le "$max_attempts" ]; do
    log "Internet check attempt $attempt/$max_attempts .."
    for h in $hosts; do
      if ping -c 1 -W 5 "$h" >/dev/null 2>&1; then
        log "Ping success to $h"
        return 0
      fi
    done
    if command -v curl >/dev/null 2>&1; then
      if curl -s --max-time 5 http://clients3.google.com/generate_204 >/dev/null 2>&1; then
        log "HTTP generate_204 success (curl)"
        return 0
      fi
    fi
    attempt=$((attempt + 1))
    sleep 3
  done

  log "Poor/No internet connection after $max_attempts attempts"
  return 1
}

# requirement checks
check_requirement() {
  log "Verifying your module setup"
  log "-------------------------------"
  log "    Installed Modules List"
  log "-------------------------------"
  local found_any=0
  local shamiko=0
  local nohello=0
  local susfs=0

  [ -d "$MODSDIR/zygisk_shamiko" ] && { log "Shamiko"; shamiko=1; found_any=1; }
  [ -d "$MODSDIR/zygisk_nohello" ] && { log "Nohello"; nohello=1; found_any=1; }
  [ -d "$MODSDIR/zygisksu" ] && { log "ZygiskSU"; found_any=1; }
  [ -d "$MODSDIR/playintegrityfix" ] && { log "Play Integrity Fix"; found_any=1; }
  [ -d "$MODSDIR/susfs4ksu" ] && { log "SUSFS-FOR-KERNELSU"; susfs=1; found_any=1; }
  [ -d "$MODSDIR/tricky_store" ] && { log "Tricky Store"; found_any=1; }

  if [ "$found_any" -eq 0 ]; then
    log "Shamiko"
    log "No Hello"
    log "Zygisk Next"
    log "Play Integrity Fix"
    log "SUSFS"
    log "Tricky Store"
  fi

  local zcount=0
  for z in zygisksu rezygisk neozygisk; do
    [ -d "$MODSDIR/$z" ] && zcount=$((zcount + 1))
  done

  if [ "$zcount" -gt 1 ]; then
    log " "
    log "❌ Multiple Zygisk modules detected"
    log "   Please only use one zygisk module"
    log " "
  else
    log " "
    log "No conflicts detected"
  fi

  # Extra conflict checks
  if [ "$shamiko" -eq 1 ] && [ "$nohello" -eq 1 ]; then
    log "⚠️ Shamiko + Nohello detected"
    log "   Please use only one of them"
    log " "
  fi

  if [ "$shamiko" -eq 1 ] && [ "$susfs" -eq 1 ]; then
    log "⚠️ Shamiko + SUSFS detected"
    log "   Nohello & SUSFS doesn't work properly together"
    log " "
  fi
}

# compute sha256 with fallbacks
compute_sha256() {
  [ ! -f "$1" ] && return 1
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
    return 0
  fi
  # busybox sha256sum
  if [ -x "$bbpath" ] && "$bbpath" sha256sum "$1" >/dev/null 2>&1; then
    "$bbpath" sha256sum "$1" | awk '{print $1}'
    return 0
  fi
  # shasum (toybox)
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
    return 0
  fi
  # openssl
  if command -v openssl >/dev/null 2>&1; then
    # openssl outputs "SHA256(filename)= <hash>"
    openssl dgst -sha256 "$1" 2>/dev/null | awk '{print $NF}'
    return 0
  fi
  # no supported tool found
  return 1
}

check_apk_hash() {
  if [ ! -f "$apkfile" ]; then
    return 1
  fi
  local found
  found=$(compute_sha256 "$apkfile" 2>/dev/null)
  if [ -z "$found" ]; then
    log "No sha256 tool available to verify apk"
    return 1
  fi
  log "Computed APK sha256: $found"
  if [ "$found" = "$expected_hash" ]; then
    return 0
  else
    return 1
  fi
}

# downloader
download_apk() {
  local attempt=1
  while [ $attempt -le $max_retries ]; do
    log "Downloading playstore.apk (attempt $attempt/$max_retries).."
    rm -f "$apkfile"
    if command -v wget >/dev/null 2>&1; then
      wget --timeout=30 -O "$apkfile" "$url" >/dev/null 2>&1
      dl_status=$?
    elif command -v curl >/dev/null 2>&1; then
      curl -L --max-time 60 -o "$apkfile" "$url" >/dev/null 2>&1
      dl_status=$?
    elif [ -x "$bbpath" ]; then
      # BusyBox wget if present
      "$bbpath" wget -O "$apkfile" "$url" >/dev/null 2>&1
      dl_status=$?
    else
      log "No downloader (wget/curl/busybox) available"
      dl_status=2
    fi

    if [ "$dl_status" -ne 0 ] || [ ! -f "$apkfile" ]; then
      log "Download failed (status $dl_status)"
    else
      if check_apk_hash; then
        log "Download verified successfully"
        return 0
      else
        log "Hash mismatch after download (attempt $attempt). Removing corrupt file"
        rm -f "$apkfile"
      fi
    fi

    attempt=$((attempt + 1))
    sleep 2
  done

  log "All $max_retries download attempts failed"
  return 1
}

# compress APKs (backup)
compress_apks() {
  archive_path="$apkdir/PlayStoreBackup.tar"
  rm -rf "$splitsdir"
  mkdir -p "$splitsdir" || { log "Failed to create splitsdir: $splitsdir"; return 1; }

  found=0
  apk_paths=$(pm path com.android.vending 2>/dev/null | awk -F: '{print $2}')
  for apk_path in $apk_paths; do
    if [ -n "$apk_path" ] && [ -f "$apk_path" ]; then
      cp "$apk_path" "$splitsdir/" && log "Backup created: $(basename "$apk_path")"
      found=1
    fi
  done

  if [ "$found" -eq 0 ]; then
    log "No APKs found via pm path, searching fallback Phonesky.apk.."
    if [ -x "$bbpath" ]; then
      sys_apk=$("$bbpath" find /system /system_ext /product -type f -name "Phonesky.apk" 2>/dev/null | head -n 1)
    else
      if command -v find >/dev/null 2>&1; then
        sys_apk=$(find /system /system_ext /product -type f -name "Phonesky.apk" 2>/dev/null | head -n 1)
      else
        sys_apk=""
      fi
    fi
    if [ -n "$sys_apk" ] && [ -f "$sys_apk" ]; then
      cp "$sys_apk" "$splitsdir/" && log "Copied fallback system APK: $sys_apk"
      found=1
    else
      log "Fallback Phonesky.apk not found"
    fi
  fi

  if [ "$found" -eq 0 ]; then
    log "No APKs to compress"
    return 1
  fi
}

# get Play Store version
get_version() {
  dumpsys package com.android.vending 2>/dev/null | awk -F= '/versionName/ {print $2; exit}' | tr -d '\r'
}

# Main
check_requirement
log "Starting Play Store installer script"

bbpath=$(shockwave 2>/dev/null)
[ -n "$bbpath" ] || bbpath="/data/adb/ksu/bin/busybox"
log "BusyBox Path: $bbpath"

log "Checking internet.."
if ! internet; then
  log "No internet available. Exiting"
  exit 1
fi

compress_apks || log "compress_apks failed or nothing to backup (continuing)"

log "Nuking Play Store updates"
pm uninstall com.android.vending >/dev/null 2>&1 || log "Playstore set to stock version"
sleep 2

# Use custom PIF fingerprint 
log "Settings custom fingerprint for PIF"
sh "/data/adb/modules/playintegrity/webroot/common_scripts/pif.sh"
  
ver_after=$(get_version)
log "Play Store version: ${ver_after:-<none>}"
major=$(echo "${ver_after:-0}" | cut -d'.' -f1)
if ! echo "$major" | grep -qE '^[0-9]+$'; then major=0; fi
log "Detected major version: $major"

if [ "$major" -lt 44 ]; then
  log "Target to be installed: 44.0.28"

  if check_apk_hash; then
    log "Existing APK present and SHA256 verified, skipping download"
  else
    log "APK missing or corrupt, will download now (max retries: $max_retries)"
    if ! download_apk; then
      log "Download & verification failed. Exiting"
      exit 1
    fi
  fi

  # install now 
  if [ -f "$apkfile" ]; then
    log "Installing $apkfile .."
    pm install -r "$apkfile" >/dev/null 2>&1
    if [ $? -ne 0 ]; then
      log "pm install failed"
      log "Please update the app manually"
      log "location: $apkfile"
#      exit 1
    fi
  else
    log "APK file missing unexpectedly. Exiting"
    exit 1
  fi

  log "Clearing Play Store data.."
  pm clear com.android.vending >/dev/null 2>&1 || log "pm clear returned non-zero"

  # one-time execution guard for action.sh to avoid recursion
  if [ -f "/data/adb/modules/playintegrity/action.sh" ] && [ ! -f "$apkdir/.action_ran" ]; then
    log "Running default action"
    sh "/data/adb/modules/playintegrity/action.sh"
    touch "$apkdir/.action_ran"
  else
    log "action.sh already ran or not present"
  fi

  log "PLEASE REBOOT YOUR DEVICE TO APPLY CHANGES"
else
  # version already good, no install needed, but still run action.sh once if not done
  if [ -f "/data/adb/modules/playintegrity/action.sh" ] && [ ! -f "$apkdir/.action_ran" ]; then
    log "Play Store >=44, running default action"
    sh "/data/adb/modules/playintegrity/action.sh"
    touch "$apkdir/.action_ran"
  fi
  log "Play Store version >=44, no install needed"
fi

log "Script finished"
rm -rf "$apkdir/.action_ran"
exit 0