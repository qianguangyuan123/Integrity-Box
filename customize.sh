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
FINGERPRINT=$(getprop ro.system.build.fingerprint)
SE=$(getenforce)
KERNEL=$(uname -r)

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
    chmod +x "$MODPATH/action.sh"
    sh "$MODPATH/action.sh" > /dev/null 2>&1
}

# Clean up old logs and files
cleanup() {
    chmod +x "$SCRIPT/cleanup.sh"
    sh "$SCRIPT/cleanup.sh"
}

setup_keybox() {
  local MOD="$1/keybox"
  local TRICKY="/data/adb/tricky_store"
  local files="secondary_keybox.xml aosp_keybox.xml"

  # Create target directory if missing
  [ ! -d "$TRICKY" ] && mkdir -p "$TRICKY" && chmod 700 "$TRICKY"

  # Move files
  for f in $files; do
    local src="$MOD/$f"
    local dst="$TRICKY/$f"
    [ ! -f "$dst" ] && mv "$src" "$dst" && chmod 600 "$dst"
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
    debug " ✦ Kernel Version : $KERNEL"
    debug " ✦ SELinux Status : $SE"
    debug " ✦ ROM Type       : $ROM_TYPE"
    debug " ✦ Build Date     : $BUILD_DATE"
    debug " ✦ Fingerprint    : $FINGERPRINT"
    debug "_________________________________________"
    debug
    debug
    debug
}

# Release the source
release_source() {
    [ -f "/data/adb/Box-Brain/noredirect" ] && return 0
    nohup am start -a android.intent.action.VIEW -d "https://t.me/MeowDump" > /dev/null 2>&1 &
}

# Enable recommended settings
enable_recommended_settings() {
    debug " ✦ Enabling Recommended Settings "
    touch "$FLAG/NoLineageProp"
    touch "$FLAG/noredirect"
    touch "$FLAG/advanced"
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
cp "$MODPATH/fingerprint/custom.pif.prop" "$MODPATH/custom.pif.prop"

# Quote of the day 
cat <<EOF > $LOG_DIR/.verify
YourMindIsAWeaponTrainItToSeeOpportunityNotObstacles
EOF

# remove old module id to avoid conflict
if [ -d /data/adb/modules/playintegrity ]; then
    touch "/data/adb/modules/playintegrity/remove"
fi

# Start the installation process
install_module

##########################################
# adapted from Play Integrity Fork by @osm0sis
# source: https://github.com/osm0sis/PlayIntegrityFork
# license: GPL-3.0
##########################################

# Allow a scripts-only mode for older Android (<10) which may not require the Zygisk components
if [ -f /sdcard/zygisk ]; then
    debug " ✦ Installing global scripts only"
    debug " ✦ Disabled: Zygisk Attestation fallback"
    debug " ✦ Disabled: Device Spoofing"
#    touch /sdcard/zygisk
    sed -i 's/\(description=\)\(.*\)/\1[Scripts-only mode] \2/' $MODPATH/module.prop
#    [ -f /data/adb/modules/playintegrityfix/uninstall.sh ] && sh /data/adb/modules/playintegrityfix/uninstall.sh
    rm -rf $MODPATH/app_replace_list.txt \
        $MODPATH/autopif2.sh $MODPATH/classes.dex \
        $MODPATH/common_setup.sh $MODPATH/custom.app_replace_list.txt \
        $MODPATH/custom.pif.json $MODPATH/custom.pif.prop  \
        $MODPATH/example.pif.prop $MODPATH/migrate.sh \
        $MODPATH/pif.json $MODPATH/pif.prop $MODPATH/zygisk \
        /data/adb/modules/playintegrityfix/custom.app_replace_list.txt \
        /data/adb/modules/playintegrityfix/custom.pif.json \
        /data/adb/modules/playintegrityfix/custom.pif.prop \
        /data/adb/modules/playintegrityfix/skippersistprop \
        /data/adb/modules/playintegrityfix/system \
#        /data/adb/modules/playintegrityfix/uninstall.sh
fi

# Copy any disabled app files to updated module
if [ -d /data/adb/modules/playintegrityfix/system ]; then
    debug " ✦ Restoring disabled ROM apps configuration"
    cp -afL /data/adb/modules/playintegrityfix/system $MODPATH
fi

# Copy any supported custom files to updated module
for FILE in custom.app_replace_list.txt custom.pif.json custom.pif.prop skipdelprop skippersistprop uninstall.sh; do
    if [ -f "/data/adb/modules/playintegrityfix/$FILE" ]; then
        debug " ✦ Restoring $FILE"
        cp -af /data/adb/modules/playintegrityfix/$FILE $MODPATH/$FILE
    fi
done

# Warn if potentially conflicting modules are installed
if [ -d /data/adb/modules/MagiskHidePropsConf ]; then
    debug " ✦ MagiskHidePropsConfig (MHPC) module may cause issues with PIF"
fi

# Run common tasks for installation and boot-time
if [ -d "$MODPATH/zygisk" ]; then
    . $MODPATH/common_func.sh
    . $MODPATH/common_setup.sh
fi

# Migrate custom.pif.json to latest defaults if needed
if [ -f "$MODPATH/custom.pif.json" ]; then
    if ! grep -q "api_level" $MODPATH/custom.pif.json || ! grep -q "verboseLogs" $MODPATH/custom.pif.json || ! grep -q "spoofVendingFinger" $MODPATH/custom.pif.json; then
        debug " ✦ Running migration script on custom.pif.json:"
        debug " "
        chmod 755 $MODPATH/migrate.sh
        sh $MODPATH/migrate.sh --install --force --advanced $MODPATH/custom.pif.json
        debug " "
    fi
fi

# Clean up any leftover files from previous deprecated methods
rm -f /data/data/com.google.android.gms/cache/pif.prop /data/data/com.google.android.gms/pif.prop \
    /data/data/com.google.android.gms/cache/pif.json /data/data/com.google.android.gms/pif.json

# Disable zygiskless installation on next installation
[ -f /sdcard/zygisk ] && rm -f /sdcard/zygisk

display_footer
exit 0
