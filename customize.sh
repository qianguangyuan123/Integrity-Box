#!/system/bin/sh

# Module and log directory paths
MODDIR="${0%/*}"
LOG_DIR="/data/adb/Box-Brain/Integrity-Box-Logs"
INSTALL_LOG="$LOG_DIR/Installation.log"
SCRIPT="$MODPATH/webroot/common_scripts"
SRC="/data/adb/modules_update/playintegrityfix/module.prop"
DEST="/data/adb/modules/playintegrityfix/module.prop"
FLAG="/data/adb/Box-Brain"

# Create log directory if it doesn't exist
mkdir -p "$LOG_DIR" || true
mkdir -p "/data/adb/modules/playintegrityfix"

# Logger
debug() {
    echo "$1" | tee -a "$INSTALL_LOG"
}

# Module info variables
MODNAME=$(grep_prop name $TMPDIR/module.prop)
MODVER=$(grep_prop version $TMPDIR/module.prop)
AUTHOR=$(grep_prop author $TMPDIR/module.prop)
TIME=$(date "+%d, %b - %H:%M %Z")

# Gather system information
BRAND=$(getprop ro.product.brand)
MODEL=$(getprop ro.product.model)
DEVICE=$(getprop ro.product.device)
ANDROID=$(getprop ro.system.build.version.release)
SDK=$(getprop ro.system.build.version.sdk)
ARCH=$(getprop ro.product.cpu.abi)
BUILD_DATE=$(getprop ro.system.build.date)
ROM_TYPE=$(getprop ro.system.build.type)
SDK=$(getprop ro.build.version.sdk)
SE=$(getenforce)

# Display module details
display_header() {
    debug
    debug "========================================="
    debug "          Module Information     "
    debug "========================================="
    debug " ✦ Module Name   : $MODNAME"
    debug " ✦ Version       : $MODVER"
    debug " ✦ Author        : $AUTHOR"
    debug " ✦ Started at    : $TIME"
    debug "_________________________________________"
    debug
    debug
    debug
}

# Verify module integrity
check_integrity() {
    debug "========================================="
    debug "          Integrity Box Installer    "
    debug "========================================="
    debug " ✦ Verifying Module Integrity    "
    
    if [ -n "$ZIPFILE" ] && [ -f "$ZIPFILE" ]; then
        if [ -f "$MODPATH/verify.sh" ]; then
            if sh "$MODPATH/verify.sh"; then
                debug " ✦ Module integrity verified." > /dev/null 2>&1
            else
                debug " ✘ Module integrity check failed!"
                exit 1
            fi
        else
            debug " ✘ Missing verification script!"
            exit 1
        fi
    fi
}

# Setup environment and permissions
setup_environment() {
    debug " ✦ Setting up Environment "
    chmod +x "$SCRIPT/key.sh"
    sh "$SCRIPT/key.sh" #> /dev/null 2>&1
}

hizru() {
    FLAG="/data/adb/Box-Brain"
    FLAG_FILE="$FLAG/skip"
    LOG_DIR="/data/adb/Box-Brain/Integrity-Box-Logs"
    LOG_FILE="$LOG_DIR/skip.log"

    mkdir -p "$FLAG" "$LOG_DIR"

    PKGS="com.samsung.android.app.updatecenter com.oplus.romupdate"
    FOUND=0
    TS="$(date '+%Y-%m-%d %H:%M:%S')"

    for pkg in $PKGS; do
        if pm list packages -s 2>/dev/null | grep -q "^package:$pkg$"; then
            FOUND=1
            echo "$TS | PM_DETECTED | $pkg" >> "$LOG_FILE"
        elif find /system /product /system_ext /apex -type d -name "*$pkg*" 2>/dev/null | grep -q .; then
            FOUND=1
            echo "$TS | FS_DETECTED | $pkg" >> "$LOG_FILE"
        else
            echo "$TS | NOT_FOUND | $pkg" >> "$LOG_FILE"
        fi
    done

    if [ "$FOUND" -eq 1 ]; then
        touch "$FLAG_FILE"
        echo "$TS | ACTION | skip flag created" >> "$LOG_FILE"
        return 0
    fi

    echo "$TS | ACTION | no skip required" >> "$LOG_FILE"
    return 1
}

# Clean up old logs and files
cleanup() {
    chmod +x "$SCRIPT/cleanup.sh"
    sh "$SCRIPT/cleanup.sh"
}

setup_keybox() {
  local BASE="$1"
  [ -z "$BASE" ] && return 0

  local SRC="$BASE/keybox"
  local DST="/data/adb/tricky_store"

  # Ensure destination directory exists
  [ -d "$DST" ] || {
    mkdir -p "$DST" || return 1
    chmod 700 "$DST"
  }

  for f in keybox2.xml keybox3.xml; do
    [ -f "$DST/$f" ] && continue
    [ -f "$SRC/$f" ] || continue
    cp "$SRC/$f" "$DST/$f" || continue
    chmod 600 "$DST/$f"
    chown root:root "$DST/$f" 2>/dev/null
  done
}

# Create necessary directories if missing
prepare_directories() {
    debug " ✦ Preparing Required Directories  "
    [ ! -d "/data/adb/modules/playintegrity" ] && mkdir -p "/data/adb/modules/playintegrity"
    [ ! -f "$SRC" ] && return 1
}

# Handle module prop file
handle_module_props() {
    debug " ✦ Handling Module Properties "
    touch "/data/adb/modules/playintegrityfix/update"
    cp "$SRC" "$DEST"
}

# Verify boot hash file
check_boot_hash() {
    debug " ✦ Creating Verified Boot Hash config     "
    if [ ! -f "/data/adb/Box-Brain/hash.txt" ]; then
        touch "/data/adb/Box-Brain/hash.txt"
    fi
}

# Gather additional system info
gather_system_info() {
    debug "========================================="
    debug "          Gathering System Info "
    debug "========================================="
    debug " ✦ Device Brand   : $BRAND"
    debug " ✦ Device Model   : $MODEL"
    debug " ✦ Android Version: $ANDROID (SDK $SDK)"
    debug " ✦ Architecture   : $ARCH"
    debug " ✦ SELinux Status : $SE"
    debug " ✦ ROM Type       : $ROM_TYPE"
    debug " ✦ Build Date     : $BUILD_DATE"
    debug "_________________________________________"
    debug
    debug
    debug
}

# Release the source
release_source() {
    [ -f "/data/adb/Box-Brain/noredirect" ] && return 0
    nohup am start -a android.intent.action.VIEW -d "https://t.me/MeowRedirect" > /dev/null 2>&1 &
}

# Enable recommended settings
enable_recommended_settings() {
    debug " ✦ Enabling Recommended Settings "
    touch "$FLAG/NoLineageProp"
    touch "$FLAG/migrate_force"
    touch "$FLAG/run_migrate"
    touch "$FLAG/noredirect"
    touch "$FLAG/nodebug"
    touch "$FLAG/encrypt"
    touch "$FLAG/build"
    touch "$FLAG/twrp"
    touch "$FLAG/tag"
}

# Final footer message
display_footer() {
    debug "_________________________________________"
    debug
    debug "             Installation Completed "
    debug "   This module was released by 𝗠𝗘𝗢𝗪 𝗗𝗨𝗠𝗣"
    debug
    debug
}

# Main installation flow
install_module() {
    display_header
    gather_system_info
    check_integrity
    setup_environment
    hizru
    prepare_directories
    cleanup
    check_boot_hash
    setup_keybox "$MODPATH"
    handle_module_props
    release_source
    enable_recommended_settings
}

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

# Copy local fingerprint to correct path so that user doesn't have to fetch it manually after installation 
if [ ! -f "/data/adb/modules/playintegrityfix/service.sh" ]; then
    cp "$MODPATH/fingerprint/custom.pif.prop" "$MODPATH/custom.pif.prop"
fi

# Quote of the day 
cat <<EOF > $LOG_DIR/.verify
TrueStrengthNeedsNoAudience
EOF

# remove old module id to avoid conflict
if [ -d /data/adb/modules/playintegrity ]; then
    touch "/data/adb/modules/playintegrity/remove"
fi

# Start the installation process
install_module

debug " ✦ Setting IntegrityBox Profile"
if [ "$SDK" -ge 33 ]; then
    touch "$FLAG/advanced"
else
    touch "$FLAG/legacy"
fi

debug " ✦ Detecting ROM signature"
# Get the signature of the "android" package
SIG=$(pm dump android 2>/dev/null | grep -A1 "signatures:" | tail -n1 | tr -d '[:space:]')

case "$SIG" in
    # Known AOSP test key hex prefixes
    *30820122300d06092a864886f70d01010105000382010f00*|\
    *30820122300d06092a864886f70d01010105000382010f01*)
        touch "$FLAG/test-key"
        ;;
    *)
        touch "$FLAG/release-key"
        ;;
esac

# Write security patch file if missing 
if [ ! -f /data/adb/tricky_store/security_patch.txt ]; then
cat <<EOF > /data/adb/tricky_store/security_patch.txt
all=2026-02-01
EOF
fi

##########################################
# adapted from Play Integrity Fork by @osm0sis
# source: https://github.com/osm0sis/PlayIntegrityFork
# license: GPL-3.0
##########################################

# Zygiskless installation 
if [ -e /sdcard/zygisk ] || [ -f /data/adb/Box-Brain/zygisk ]; then
    debug " ✦ Proceeding Zygiskless Installation"
    debug " ✦ Disabled: Zygisk Attestation fallback"
    debug " ✦ Enabled:  Pixel Mode"
    touch "$FLAG/zygisk"
    touch "$FLAG/keybox"
    touch "$FLAG/json"
    sed -i 's/^description=.*/description=Pixel Mode 🌱 has been enabled, all zygisk related components has been disabled/' "$MODPATH/module.prop"
    rm -rf $MODPATH/app_replace_list.txt \
        $MODPATH/autopif2.sh $MODPATH/classes.dex \
        $MODPATH/common_setup.sh $MODPATH/custom.app_replace_list.txt \
        $MODPATH/custom.pif.json \
        $MODPATH/example.pif.prop \
        $MODPATH/pif.json $MODPATH/pif.prop $MODPATH/zygisk \
        /data/adb/modules/playintegrityfix/custom.app_replace_list.txt \
        /data/adb/modules/playintegrityfix/custom.pif.json \
        /data/adb/modules/playintegrityfix/skippersistprop \
        /data/adb/modules/playintegrityfix/system
fi

# Copy any disabled app files to updated module
if [ -d /data/adb/modules/playintegrityfix/system ]; then
    debug " ✦ Restoring disabled ROM apps configuration"
    cp -afL /data/adb/modules/playintegrityfix/system $MODPATH
fi

# Warn if potentially conflicting modules are installed
if [ -d /data/adb/modules/MagiskHidePropsConf ]; then
    debug " ✦ MagiskHidePropsConfig (MHPC) module may cause issues with PIF"
    debug " ✦ Kindly disable or remove it"
fi

# Run common tasks for installation and boot-time
if [ -d "$MODPATH/zygisk" ]; then
    . $MODPATH/common_func.sh
    . $MODPATH/common_setup.sh
fi

# Clean up any leftover files from previous deprecated methods
rm -f /data/data/com.google.android.gms/cache/pif.prop /data/data/com.google.android.gms/pif.prop \
    /data/data/com.google.android.gms/cache/pif.json /data/data/com.google.android.gms/pif.json

# Remove flag from /sdcard to avoid detection 
[ -f /sdcard/zygisk ] || [ -d /sdcard/zygisk ] && rm -rf /sdcard/zygisk

display_footer
exit 0
