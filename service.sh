#!/system/bin/sh
MODPATH="${0%/*}"
. $MODPATH/common_func.sh

# Module path and file references
LOG_DIR="/data/adb/Box-Brain/Integrity-Box-Logs"
PROP="/data/adb/modules/playintegrity/system.prop"
LINE="ro.crypto.state=encrypted"
LINE2="ro.build.tags=release-keys"
LINE3="ro.build.type=user"
PIF="/data/adb/modules/playintegrityfix"
LOG="$LOG_DIR/service.log"
LOG2="$LOG_DIR/encrypt.log"
LOG3="$LOG_DIR/autopif.log"
LOG4="$LOG_DIR/twrp.log"
LOG5="$LOG_DIR/tag.log"
LOG6="$LOG_DIR/build.log"

# Log folder
mkdir -p "$LOGDIR"

# Logger function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') | $1" | tee -a "$LOG"
}

# SELinux spoofing
if [ -f /data/adb/Box-Brain/selinux ]; then
    if command -v setenforce >/dev/null 2>&1; then
        current=$(getenforce)
        if [ "$current" != "Enforcing" ]; then
            setenforce 1
            log "SELINUX Spoofed successfully"
        fi
    fi
fi

# Module install path
export MODPATH="/data/adb/modules/playintegrity"

NO_LINEAGE_FLAG="/data/adb/Box-Brain/NoLineageProp"
NODEBUG_FLAG="/data/adb/Box-Brain/nodebug"
TAG_FLAG="/data/adb/Box-Brain/tag"

TMP_PROP="$MODPATH/tmp.prop"
SYSTEM_PROP="$MODPATH/system.prop"
> "$TMP_PROP" # clear old temp file

# Build summary of active flags
FLAGS_ACTIVE=""
[ -f "$NO_LINEAGE_FLAG" ] && FLAGS_ACTIVE="$FLAGS_ACTIVE NoLineageProp"
[ -f "$NODEBUG_FLAG" ] && FLAGS_ACTIVE="$FLAGS_ACTIVE nodebug"
[ -f "$TAG_FLAG" ] && FLAGS_ACTIVE="$FLAGS_ACTIVE tag"

if [ -n "$FLAGS_ACTIVE" ]; then
    log "Prop sanitization flags active: $FLAGS_ACTIVE"
    log "Preparing temporary prop file..."
    getprop | grep "userdebug" >> "$TMP_PROP"
    getprop | grep "test-keys" >> "$TMP_PROP"
    getprop | grep "lineage_" >> "$TMP_PROP"

    # Basic cleanup
    sed -i 's///g' "$TMP_PROP"
    sed -i 's/: /=/g' "$TMP_PROP"
else
    log "No prop sanitization flags found. Skipping."
fi

# LineageOS cleanup
if [ -f "$NO_LINEAGE_FLAG" ]; then
    log "NoLineageProp flag detected. Deleting LineageOS props..."
    for prop in \
        ro.lineage.build.version \
        ro.lineage.build.version.plat.rev \
        ro.lineage.build.version.plat.sdk \
        ro.lineage.device \
        ro.lineage.display.version \
        ro.lineage.releasetype \
        ro.lineage.version \
        ro.lineagelegal.url; do
        resetprop --delete "$prop"
    done
    sed -i 's/lineage_//g' "$TMP_PROP"
    log "LineageOS props sanitized."
fi

# userdebug to user
if [ -f "$NODEBUG_FLAG" ]; then
    if grep -q "userdebug" "$TMP_PROP"; then
        sed -i 's/userdebug/user/g' "$TMP_PROP"
    fi
    log "userdebug to user sanitization applied."
fi

# test-keys to release-keys
if [ -f "$TAG_FLAG" ]; then
    if grep -q "test-keys" "$TMP_PROP"; then
        sed -i 's/test-keys/release-keys/g' "$TMP_PROP"
    fi
    log "test-keys to release-keys sanitization applied."
fi

# Finalize system.prop
if [ -s "$TMP_PROP" ]; then
    log "Sorting and creating final system.prop..."
    sort -u "$TMP_PROP" > "$SYSTEM_PROP"
    rm -f "$TMP_PROP"
    log "system.prop created at $SYSTEM_PROP."

    log "Waiting 30 seconds before applying props..."
    sleep 30

    log "Applying props via resetprop..."
    resetprop -n --file "$SYSTEM_PROP"
    log "Prop sanitization applied from system.prop"
fi

# Explicit fingerprint sanitization
if [ -f "$NODEBUG_FLAG" ] || [ -f "$TAG_FLAG" ]; then
    fp=$(getprop ro.build.fingerprint)
    fp_clean="$fp"

    [ -f "$NODEBUG_FLAG" ] && fp_clean=${fp_clean/userdebug/user}
    [ -f "$TAG_FLAG" ] && {
        fp_clean=${fp_clean/test-keys/release-keys}
        fp_clean=${fp_clean/dev-keys/release-keys}
    }

    if [ "$fp" != "$fp_clean" ]; then
        resetprop ro.build.fingerprint "$fp_clean"
        [ -f "$NODEBUG_FLAG" ] && resetprop ro.build.type "user"
        [ -f "$TAG_FLAG" ] && resetprop ro.build.tags "release-keys"
        log "Fingerprint sanitized to $fp_clean"
    else
        log "Fingerprint already clean. No changes applied."
    fi
fi

# Spoof Encryption 
{
  echo "ENCRYPT CHECK ($(date))"

  if [ -f /data/adb/Box-Brain/encrypt ]; then
    if grep -qxF "$LINE" "$PROP"; then
      echo "Line already exists, no action needed"
    else
      echo "$LINE" >> "$PROP"
      echo "Spoofed prop: $LINE"
    fi
  else
    if grep -qxF "$LINE" "$PROP"; then
      sed -i "\|^$LINE\$|d" "$PROP"
      echo "Removed line: $LINE"
    else
      echo "Line not present, no action needed"
    fi
  fi

  echo
} >> "$LOG2" 2>&1

# Spoof Tag 
{
  echo "TAG CHECK ($(date))"

  if [ -f /data/adb/Box-Brain/tag ]; then
    if grep -qxF "$LINE2" "$PROP"; then
      echo "Line already exists, no action needed"
    else
      echo "$LINE2" >> "$PROP"
      echo "Spoofed prop: $LINE"
    fi
  else
    if grep -qxF "$LINE2" "$PROP"; then
      sed -i "\|^$LINE2\$|d" "$PROP"
      echo "Removed line: $LINE2"
    else
      echo "Line not present, no action needed"
    fi
  fi

  echo
} >> "$LOG5" 2>&1

# Spoof Build 
{
  echo "BUILD CHECK ($(date))"

  if [ -f /data/adb/Box-Brain/build ]; then
    if grep -qxF "$LINE3" "$PROP"; then
      echo "Line already exists, no action needed"
    else
      echo "$LINE3" >> "$PROP"
      echo "Spoofed prop: $LINE3"
    fi
  else
    if grep -qxF "$LINE3" "$PROP"; then
      sed -i "\|^$LINE3\$|d" "$PROP"
      echo "Removed line: $LINE3"
    else
      echo "Line not present, no action needed"
    fi
  fi

  echo
} >> "$LOG6" 2>&1

# Rename twrp folder to avoid root detection
{
  echo "TWRP/FOX RENAME ($(date))"
  echo
  # Run for both TWRP and Fox
  rename_recovery_folder "/data/adb/Box-Brain/twrp" "/sdcard/TWRP" "TWRP"
  rename_recovery_folder "/data/adb/Box-Brain/fox" "/sdcard/Fox" "Fox"

} >> "$LOG4" 2>&1

##########################################
# adapted from Play Integrity Fork by @osm0sis
# source: https://github.com/osm0sis/PlayIntegrityFork
# license: GPL-3.0
##########################################

if [ -d "/data/adb/modules/playintegrityfix" ]; then
    pif "PIF module detected, Script mode has been disabled"
    pif " [ service.sh ] "
    pif " "
    exit 0
fi

# Conditional sensitive properties
# Magisk Recovery Mode
resetprop_if_match ro.boot.mode recovery unknown
resetprop_if_match ro.bootmode recovery unknown
resetprop_if_match vendor.boot.mode recovery unknown

# SELinux
resetprop_if_diff ro.boot.selinux enforcing
# use delete since it can be 0 or 1 for enforcing depending on OEM
if ! $SKIPDELPROP; then
    delprop_if_exist ro.build.selinux
fi
# use toybox to protect stat access time reading
if [ "$(toybox cat /sys/fs/selinux/enforce)" = "0" ]; then
    chmod 640 /sys/fs/selinux/enforce
    chmod 440 /sys/fs/selinux/policy
fi

# Conditional late sensitive properties
# must be set after boot_completed for various OEMs
{
until [ "$(getprop sys.boot_completed)" = "1" ]; do
    sleep 1
done

# SafetyNet/Play Integrity + OEM
# avoid bootloop on some Xiaomi devices
resetprop_if_diff ro.secureboot.lockstate locked
# avoid breaking Realme fingerprint scanners
resetprop_if_diff ro.boot.flash.locked 1
resetprop_if_diff ro.boot.realme.lockstate 1
# avoid breaking Oppo fingerprint scanners
resetprop_if_diff ro.boot.vbmeta.device_state locked
# avoid breaking OnePlus display modes/fingerprint scanners
resetprop_if_diff vendor.boot.verifiedbootstate green
# avoid breaking OnePlus/Oppo fingerprint scanners on OOS/ColorOS 12+
resetprop_if_diff ro.boot.verifiedbootstate green
resetprop_if_diff ro.boot.veritymode enforcing
resetprop_if_diff vendor.boot.vbmeta.device_state locked

# Other
resetprop_if_diff sys.oem_unlock_allowed 0

}&
