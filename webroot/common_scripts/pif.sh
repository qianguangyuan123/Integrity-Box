#!/system/bin/sh

MODDIR="/data/adb/modules/playintegrity/toolbox"
MODULE_PROP="/data/adb/modules/playintegrityfix/module.prop"

SRC_PIF="$MODDIR/pif.prop"
SRC_FORK="$MODDIR/custom.pif.json"

DST_PIF="/data/adb/modules/playintegrityfix/pif.prop"
DST_FORK="/data/adb/modules/playintegrityfix/custom.pif.json"

LOG="/data/adb/Box-Brain/Integrity-Box-Logs/pif.log"
KILL="/data/adb/modules/playintegrity/webroot/common_scripts/kill.sh"

log() {
    echo -e "$1" | tee -a "$LOG"
}

touch "$LOG"
log "Using Integrity Box's Pixel Fingerprint"

if [ -f "$MODULE_PROP" ]; then
    AUTHOR=$(grep '^author=' "$MODULE_PROP" | cut -d= -f2-)
#    log "- Author: $AUTHOR"

    if [ "$AUTHOR" = "osm0sis & chiteroman @ xda-developers" ]; then
        if [ -f "$SRC_FORK" ]; then
            [ -f "$DST_FORK" ] && cp -f "$DST_FORK" "$DST_FORK.bak" && log "Backing up old fingerprint"
            cp "$SRC_FORK" "$DST_FORK"
            chmod 644 "$DST_FORK"
            log "Updated custom.pif.json"
        else
            log "❌ custom.pif.json not found"
        fi
    else
        if [ -f "$SRC_PIF" ]; then
            [ -f "$DST_PIF" ] && cp -f "$DST_PIF" "$DST_PIF.bak" && log "Backing up old fingerprint"
            cp "$SRC_PIF" "$DST_PIF"
            chmod 644 "$DST_PIF"
            log "Updated pif.prop"
        else
            log "❌ pif.prop not found"
        fi
    fi
else
    log "❌ playintegrityfix not found"
fi

sleep 2
[ -x "$KILL" ] || chmod +x "$KILL"
sh "$KILL"

exit 0