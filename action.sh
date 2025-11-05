#!/system/bin/sh
MODPATH="${0%/*}"
. $MODPATH/common_func.sh

# Paths
MODULE="/data/adb/modules"
MODDIR="$MODULE/playintegrity"
SCRIPT_DIR="$MODDIR/webroot/common_scripts"
UPDATE="$SCRIPT_DIR/key.sh"
PIF="$MODULE/playintegrityfix"
PROP="/data/adb/modules/playintegrity/module.prop"
URL="https://raw.githubusercontent.com/MeowDump/Integrity-Box/refs/heads/main/DUMP/notice.md"
BAK="$PROP.bak"
FLAG="/data/adb/Box-Brain/advanced"
FINGERPRINT="$PIF/custom.pif.json"
CPP="/data/adb/Box-Brain/Integrity-Box-Logs/spoofing.log"
P="/data/adb/modules/playintegrityfix/custom.pif.prop"
PATCH_DATE="2025-10-05"
PATCH_LOG="/data/adb/Box-Brain/Integrity-Box-Logs/patch.log"
TARGET_DIR="/data/adb/tricky_store"
FILE_PATH="$TARGET_DIR/security_patch.txt"
PATCH_FLAG="/data/adb/Box-Brain/patch"
PROP_MAIN="ro.build.version.security_patch"

#if [ -f "/data/adb/Box-Brain/keybox" ]; then
#  cd "/data/adb/modules/playintegrity"
#  /data/adb/python/run-python "keybox.py" /data/adb/tricky_store/keybox.xml
#  rm -rf "data/adb/Box-Brain/keybox"
#  exit 0
#fi

# Force override lineage props
if [ -f "/data/adb/Box-Brain/override" ]; then
  echo "
  
  ┈╱▔▔▔▔▔▔╲┈╭━━━━━━━━━━━━━━━╮
  ▕┈╭━╮╭━╮┈▏┃ Hello Human...┃
  ▕┈┃╭╯╰╮┃┈▏╰┳━━━━━━━━━━━━━━╯ 
  ▕┈╰╯╭╮╰╯┈▏┈┃ 
  ▕┈┈┈┃┃┈┈┈▏━╯ 
  ▕┈┈┈╰╯┈┈┈▏ 
  ▕╱╲╱╲╱╲╱╲▏
  
  "
  sh "$SCRIPT_DIR/override_lineage.sh"
  exit 0
fi

# Detect if Google Wallet is installed
if command -v pm >/dev/null 2>&1 && pm list packages | grep -q com.google.android.apps.walletnfcrel; then
  WALLET_INSTALLED=true
else
  WALLET_INSTALLED=false
fi

# Ensure log directory/file exists
mkdir -p "$(dirname "$CPP")" 2>/dev/null || true
touch "$CPP" 2>/dev/null || true

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >>"$CPP"; }

# Exit if offline
if ! megatron; then exit 1; fi

# Show header
print_header

# Description content update
{
  for p in /data/adb/modules/busybox-ndk/system/*/busybox \
           /data/adb/ksu/bin/busybox \
           /data/adb/ap/bin/busybox \
           /data/adb/magisk/busybox \
           /system/bin/busybox \
           /system/xbin/busybox; do
    [ -x "$p" ] && bb=$p && break
  done
  [ -z "$bb" ] && return 0

  C=$($bb wget -qO- "$URL" 2>/dev/null)
  if [ -n "$C" ]; then
    [ ! -f "$BAK" ] && $bb cp "$PROP" "$BAK"
    $bb sed -i '/^description=/d' "$PROP"
    echo "description=$C" >> "$PROP"
  else
    [ -f "$BAK" ] && $bb cp "$BAK" "$PROP"
  fi
} || true

# Run steps
# Update Target List
if [ ! -d "/data/adb/tricky_store" ]; then
  echo "- TrickyStore module not found"
  log_step "MISSING" "TrickyStore Module"
else
  TRICKY_DIR='/data/adb/tricky_store'
  TARGET="$TRICKY_DIR/target.txt"
  BACKUP="$TARGET.bak"
  TMP="${TARGET}.new.$$"
  success=0
  made_backup=0
  orig_selinux="$(getenforce 2>/dev/null || echo Permissive)"

  # Temporarily set SELinux permissive
  if [ "$orig_selinux" = "Enforcing" ]; then
    setenforce 0 >/dev/null 2>&1
    log "SELinux temporarily set to Permissive"
  fi

  # Backup current target
  if [ -f "$TARGET" ]; then
    mv -f "$TARGET" "$BACKUP" && made_backup=1
    log "Backup created: $BACKUP"
  fi

  # Read teeBroken status
  teeBroken="false"
  TEE_STATUS="$TRICKY_DIR/tee_status"
  if [ -f "$TEE_STATUS" ]; then
    v=$(grep -E '^teeBroken=' "$TEE_STATUS" 2>/dev/null | cut -d '=' -f2)
    [ "$v" = "true" ] && teeBroken="true"
  fi

  # Base packages
  for pkg in com.android.vending com.google.android.gms com.reveny.nativecheck \
             io.github.vvb2060.keyattestation io.github.qwq233.keyattestation \
             io.github.vvb2060.mahoshojo icu.nullptr.nativetest \
             com.google.android.contactkeys com.google.android.ims com.google.android.safetycore; do
    echo "$pkg" >> "$TMP"
  done

  # Append installed packages avoiding duplicates
  cmd package list packages -3 2>/dev/null | cut -d ":" -f2 | while read -r pkg; do
    [ -z "$pkg" ] && continue
    grep -Fxq "$pkg" "$TMP" || echo "$pkg" >> "$TMP"
  done

  # Trim spaces, remove duplicates
  sed -i 's/^[[:space:]]*//;s/[[:space:]]*$//' "$TMP"
  sort -u "$TMP" -o "$TMP"

  # Apply blacklist filtering
  BLACKLIST="/data/adb/Box-Brain/blacklist.txt"
  if [ -s "$BLACKLIST" ]; then
    sed -i 's/^[[:space:]]*//;s/[[:space:]]*$//' "$BLACKLIST"
    grep -Fvxf "$BLACKLIST" "$TMP" > "${TMP}.filtered" || true
    mv -f "${TMP}.filtered" "$TMP"
    log_step "CLEANED" "Blacklisted Apps"
  else
    log_step "SKIPPED" "Blacklist not Configured"
  fi

  # If teeBroken=true, append '!' to every package name
  if [ "$teeBroken" = "true" ]; then
    sed -i 's/$/!/' "$TMP"
    log_step "SUPPORT" "TEE Broken (added '!')"
  fi

  # Swap in atomically
  mv -f "$TMP" "$TARGET" && success=1
  log_step "UPDATED" "Target Packages"

  # Restore SELinux
  if [ "$orig_selinux" = "Enforcing" ]; then
    setenforce 1 >/dev/null 2>&1
    log "SELinux restored to Enforcing"
  fi
fi

# Update Fingerprint based on Advanced Flag
if [ -f "$FLAG" ]; then
  if [ -f "$PIF/autopif2.sh" ]; then
    sh "$PIF/autopif2.sh" -s -m -p >/dev/null 2>&1 || exit 1
    log_step "UPDATED" "Advanced Fingerprint"
  else
    log_step "MISSING" "autopif2.sh for advanced mode"
  fi
else
  if [ -f "$PIF/autopif2.sh" ]; then 
    FP_SCRIPT="$PIF/autopif2.sh"
  elif [ -f "$PIF/autopif.sh" ]; then 
    FP_SCRIPT="$PIF/autopif.sh"
  else 
    FP_SCRIPT=""
  fi

  if [ -n "$FP_SCRIPT" ]; then
    sh "$FP_SCRIPT" >/dev/null 2>&1 \
      && log_step "UPDATED" "Fingerprint" \
      || log_step "FAILED" "Updating Fingerprint"
  else
    log_step "MISSING" "PIF Module"
  fi
fi

# Only update spoofing props if Google Wallet NOT installed and advanced flag is present
if [ "$WALLET_INSTALLED" != "true" ] && [ -f "$FLAG" ]; then
  if [ -f "$P" ]; then
    cp -f "$P" "$P.bak" && log "Backup: $P.bak"
    for k in spoofProvider spoofProps spoofBuild spoofVendingFinger; do
      setval "$P" "$k" "1"
    done
    s=$(grep -m1 "^spoofProvider=" "$P" 2>/dev/null | cut -d= -f2 || echo "")
    log "Spoofing: $( [ "$s" = "1" ] || [ "$s" = "true" ] && echo "✅ Enabled" || echo "⚠️ Disabled" )"
    log_step "UPDATED" "Spoofing Props"
  else
    log_step "MISSING" "PIF Fork Module"
  fi
else
  # If wallet installed we skip only the updater; if advanced flag missing we skip updater too.
  if [ "$WALLET_INSTALLED" = "true" ]; then
    log_step "SKIPPED" "Spoofing Props update (Google Wallet)"
  else
    log_step "SKIPPED" "Spoofing Props (Disabled)"
  fi
fi

# Remove advanced settings from PROP only if advanced flag is missing (run always regardless of Google Wallet)
if [ -f "$P" ] && [ ! -f "$FLAG" ]; then
  if grep -qE '^(spoofBuild|spoofProps|spoofProvider|spoofSignature|spoofVendingSdk|spoofVendingFinger|verboseLogs)=' "$P"; then
    sed -i -E '/^(spoofBuild|spoofProps|spoofProvider|spoofSignature|spoofVendingSdk|spoofVendingFinger|verboseLogs)=/d' "$P"
    log_step "CLEANED" "Advanced settings from Fingerprint"
  else
    log_step "SKIPPED" "Default Fingerprint Detected"
  fi
fi

if [ -f "$UPDATE" ]; then
  sh "$UPDATE" >/dev/null 2>&1 && log_step "UPDATED" "Keybox" || log_step "FAILED" "Updating Keybox"
else
  log_step "MISSING" "Keybox script"
fi

# Ensure log directory exists
mkdir -p "$(dirname "$PATCH_LOG")" 2>/dev/null || true
touch "$PATCH_LOG" 2>/dev/null || true

# Format PATCH_DATE into human-readable form
HUMAN_DATE=$(date -d "$PATCH_DATE" '+%d %B %Y' 2>/dev/null)

log_patch "Patch Date   : $HUMAN_DATE"
log_patch "Applied On   : $(date '+%Y-%m-%d %H:%M:%S')"

# Ensure Tricky Store directory exists
if [ ! -d "$TARGET_DIR" ]; then
  mkdir -p "$TARGET_DIR" 2>>"$PATCH_LOG"
  log_step "CREATED" "Tricky Store folder"
fi

# Write security_patch.txt based on patch flag
if [ -f "$PATCH_FLAG" ]; then
  echo "system=prop" > "$FILE_PATH" 2>>"$PATCH_LOG"
  log_step "UPDATED" "Patch to Stock"
else
  echo "all=$PATCH_DATE" > "$FILE_PATH" 2>>"$PATCH_LOG"
  log_step "SPOOFED" "Security Patch to $PATCH_DATE"

  # Check system property and patch if needed
  CURRENT_PROP="$(getprop "$PROP_MAIN" | tr -d ' \t\r\n')"
  log_patch "Current $PROP_MAIN: $CURRENT_PROP"

  if [ "$CURRENT_PROP" != "$PATCH_DATE" ]; then
    if command -v resetprop >/dev/null 2>&1; then
      resetprop "$PROP_MAIN" "$PATCH_DATE"
      log_step "PATCHED" "$PROP_MAIN to $PATCH_DATE"
    else
      log_step "FAILED" "resetprop not found"
    fi
  else
    log_step "SKIPPED" "All Good, Resetprop not Required"
  fi
fi

log_patch "Patch handling complete"
log_patch " "

for proc in com.google.android.gms.unstable com.google.android.gms com.android.vending; do
  kill_process "$proc"
done

log_step "REVIVED" "Droidguard Processes"

echo "--------------------------------------------"
echo " "
echo " Action completed successfully."
handle_delay
exit 0
