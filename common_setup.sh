# Remove any definitely conflicting modules that are installed
if [ -d /data/adb/modules/safetynet-fix ]; then
    touch /data/adb/modules/safetynet-fix/remove
    ui_print "! Universal SafetyNet Fix (USNF) module will be removed on next reboot"
fi

# Replace/hide conflicting custom ROM injection app folders/files to disable them
LIST=$MODPATH/example.app_replace.list
[ -f "$MODPATH/custom.app_replace.list" ] && LIST=$MODPATH/custom.app_replace.list
for APP in $(grep -v '^#' $LIST); do
    if [ -e "$APP" ]; then
        case $APP in
            /system/*) HIDEPATH=$MODPATH/$APP;;
            *) HIDEPATH=$MODPATH/system/$APP;;
        esac
        if [ -d "$APP" ]; then
            mkdir -p $HIDEPATH
            if [ "$KSU" = "true" -o "$APATCH" = "true" ]; then
                setfattr -n trusted.overlay.opaque -v y $HIDEPATH
            else
                touch $HIDEPATH/.replace
            fi
        else
            mkdir -p $(dirname $HIDEPATH)
            if [ "$KSU" = "true" -o "$APATCH" = "true" ]; then
                mknod $HIDEPATH c 0 0
            else
                touch $HIDEPATH
            fi
        fi
        if [[ -d "$APP" -o "$APP" = *".apk" ]]; then
            ui_print "! $(basename $APP .apk) ROM app disabled, please uninstall any user app versions/updates after next reboot"
        fi
    fi
done
