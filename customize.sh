#!/system/bin/sh
MODDIR=${0%/*}
LOG_DIR="/data/adb/Box-Brain/Integrity-Box-Logs"
INSTALL_LOG="$LOG_DIR/Installation.log"
SCRIPT="$MODPATH/webroot/common_scripts"
PIF_DIR="/data/adb/modules/playintegrityfix"

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

# Network check 
check_network() {
  ATTEMPT=1
  MAX_ATTEMPTS=10
  TARGET="8.8.8.8"

  while [ "$ATTEMPT" -le "$MAX_ATTEMPTS" ]; do
    # Try ping first
    if command -v ping >/dev/null 2>&1; then
      if ping -c 1 -w 1 "$TARGET" >/dev/null 2>&1; then
        log " ✦ Network connectivity confirmed on attempt $ATTEMPT"
        return 0
      fi
    fi

    # Fallback: wget or curl
    if command -v wget >/dev/null 2>&1; then
      if wget -q --spider --timeout=2 http://connectivitycheck.gstatic.com/generate_204; then
        log " ✦ Network connectivity confirmed on attempt $ATTEMPT"
        return 0
      fi
    elif command -v curl >/dev/null 2>&1; then
      if curl -fs --max-time 2 http://connectivitycheck.gstatic.com/generate_204 >/dev/null; then
        log " ✦ Network connectivity confirmed on attempt $ATTEMPT"
        return 0
      fi
    fi

    # Failed attempt
    log " ✦ Network connectivity attempt $ATTEMPT failed"
    if [ "$ATTEMPT" -eq "$MAX_ATTEMPTS" ]; then
      log " ✦ Network unreachable after $MAX_ATTEMPTS attempts"
      return 1
    fi

    ATTEMPT=$((ATTEMPT + 1))
    sleep 1
  done
}

chup() {
echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_DIR/pixel.log"
}

set_resetprop() {
    PROP="$1"
    VALUE="$2"
    CURRENT=$(su -c getprop "$PROP")
    
    if [ -n "$CURRENT" ]; then
        su -c resetprop -n -p "$PROP" "$VALUE" > /dev/null 2>&1
        chup "Reset $PROP to $VALUE"
    else
        chup "Skipping $PROP, property does not exist"
    fi
}

set_simpleprop() {
    PROP="$1"
    VALUE="$2"
    CURRENT=$(su -c getprop "$PROP")
    
    if [ -n "$CURRENT" ]; then
        su -c setprop "$PROP" "$VALUE" > /dev/null 2>&1
        chup "Set $PROP to $VALUE"
    else
        chup "Skipping $PROP, property does not exist"
    fi
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

# Network connectivity check 
if ! check_network; then
  log " ✦ Network check failed, exiting"
  exit 1
fi

# Quote of the day 
cat <<EOF > $LOG_DIR/.verify
YourMindIsAWeaponTrainItToSeeOpportunityNotObstacles
EOF

# Force pif to use advanced settings
touch "/data/adb/Box-Brain/advanced"

# Entry point
batman

log " ✦ Analyzing GMS spoofing"
# Check for gms flag, skip if found
if [ -f "/data/adb/Box-Brain/gms" ]; then
    log " ✦ Skipping, GMS flag found"
elif [ -f "$PIF_DIR/module.prop" ]; then
    log " ✦ Optimizing inbuilt GMS spoofing"
    # Set/reset props if they exist
    set_resetprop persist.sys.pihooks.disable.gms_key_attestation_block true
    set_resetprop persist.sys.pihooks.disable.gms_props true
    set_simpleprop persist.sys.pihooks.disable 1
    set_simpleprop persist.sys.kihooks.disable 1
else
    log " ✦ Enabled PIF Standalone Mode"
fi

# Abnormal boot hash fixer
log " "
log " ✦ Checking for Verified Boot Hash file..."

if [ ! -f /data/adb/Box-Brain/hash.txt ]; then
    log " ✦ Building Verified Boot Hash config"
    touch /data/adb/Box-Brain/hash.txt
    log " ✦ File created successfully"
else
    log " ✦ File already exists, skipping"
fi

# Delete old logs & trash generated integrity box
chmod +x "$SCRIPT/cleanup.sh"
sh "$SCRIPT/cleanup.sh"

release_source
touch "/data/adb/Box-Brain/noredirect"
log " "
log " "
log "        ••• Installation Completed ••• "
log " "
log "    This module was released by 𝗠𝗘𝗢𝗪 𝗗𝗨𝗠𝗣"
log " "
log " "
log " "
exit 0