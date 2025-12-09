#!/system/bin/sh
MODPATH="${0%/*}"
. $MODPATH/common_func.sh

# Module path and file references
LOG_DIR="/data/adb/Box-Brain/Integrity-Box-Logs"
PROP="/data/adb/modules/playintegrityfix/system.prop"
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
  [ -f /data/adb/Box-Brain/twrp ] && hide_recovery_folders
} >> "$LOG4" 2>&1

##########################################
# adapted from Play Integrity Fork by @osm0sis
# source: https://github.com/osm0sis/PlayIntegrityFork
# license: GPL-3.0
##########################################


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
