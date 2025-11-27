#!/system/bin/sh
MODDIR=${0%/*}
LOG_DIR="/data/adb/Box-Brain/Integrity-Box-Logs"
INSTALL_LOG="$LOG_DIR/Installation.log"
SCRIPT="$MODPATH/webroot/common_scripts"
PIF_DIR="/data/adb/modules/playintegrityfix/zygisk"
SRC="/data/adb/modules_update/playintegrity/module.prop"
DEST="/data/adb/modules/playintegrity/module.prop"
UPDATE_FILE="/data/adb/modules/playintegrity/update"
FLAG="/data/adb/Box-Brain"

# create dirs
mkdir -p "$LOG_DIR" 2>/dev/null || true

echo "
    ____      __                  _ __       
   /  _/___  / /____  ____ ______(_) /___  __
   / // __ \/ __/ _ \/ __ / ___/ / __/  / / /
 _/ // / / / /_/  __/ /_/ / /  / / /_/ /_/ / 
/___/_/ /_/\__/\___/\__, /_/  /_/\__/\__, /  
                   /____/           /____/           
             ____            
            / __ )____  _  __
           / __  / __ \| |/_/
          / /_/ / /_/ />  <  
         /_____/\____/_/|_|  
                    
"

# logger
log() {
    echo "$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_DIR/installation.log"
}

# Run actions
batman() {
  if [ -n "$ZIPFILE" ] && [ -f "$ZIPFILE" ]; then
    log " "
    log " ✦ Checking Module Integrity..."

    if [ -f "$MODPATH/verify.sh" ]; then
      if sh "$MODPATH/verify.sh"; then
        log " ✦ Verification completed successfully"
      else
        log " ✘ Verification failed"
        exit 1
      fi
    else
      log " ✦ verify.sh not found ❌"
      exit 1
    fi
  fi

  log " "
  log " ✦ Setting-up Environment..."
  chmod +x "$MODPATH/action.sh"
  sh "$MODPATH/action.sh" >/dev/null 2>&1
  log " ✦ Setup Completed"
  log " "
}

release_source() {
    [ -f "/data/adb/Box-Brain/noredirect" ] && return 0
    nohup am start -a android.intent.action.VIEW -d https://t.me/MeowDump >/dev/null 2>&1 &
}

# Quote of the day 
cat <<EOF > $LOG_DIR/.verify
YourMindIsAWeaponTrainItToSeeOpportunityNotObstacles
EOF

# Entry point
batman

log " ✦ Detecting PIF"
if [ -d "$PIF_DIR" ]; then
    log " ✦ PIF Zygisk = TRUE"
else
    log " ✦ IntegrityBox's PIF = TRUE"
fi

# Abnormal boot hash fixer
log " "
log " ✦ Checking for Verified Boot Hash config..."

if [ ! -f /data/adb/Box-Brain/hash.txt ]; then
    log " ✦ Building Verified Boot Hash config"
    touch /data/adb/Box-Brain/hash.txt
    log " ✦ File created successfully"
else
    log " ✦ File already exists, skipping"
fi

#temporary fix (will fix this wen I get time)
# Create update flag if it doesn't exist
[ ! -f "$UPDATE_FILE" ] && touch "$UPDATE_FILE"

# Create destination directory if it doesn't exist
[ -f "$SRC" ] && [ ! -d "/data/adb/modules/playintegrity" ] && mkdir -p "/data/adb/modules/playintegrity"

# Copy the file if it doesn't exist at the destination
[ -f "$SRC" ] && [ ! -f "$DEST" ] && cp "$SRC" "$DEST"

# Delete old logs & trash generated integrity box
chmod +x "$SCRIPT/cleanup.sh"
sh "$SCRIPT/cleanup.sh"

release_source
# Auto enable recommended settings
touch "$FLAG/advanced"
touch "$FLAG/playstore"
touch "$FLAG/gms"
touch "$FLAG/encrypt"
touch "$FLAG/noredirect"
touch "$FLAG/nodebug"
touch "$FLAG/selinux"
log " "
log " "
log "        ••• Installation Completed ••• "
log " "
log "    This module was released by 𝗠𝗘𝗢𝗪 𝗗𝗨𝗠𝗣"
log " "
log " "
log " "
exit 0