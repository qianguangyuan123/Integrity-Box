#!/system/bin/sh

PACKAGE_NAME="com.reveny.nativecheck"

# Check if the properties exist before setting them
if getprop persist.sys.pihooks.disable.gms_props >/dev/null 2>&1; then
    su -c setprop persist.sys.pihooks.disable.gms_props true
fi

if getprop persist.sys.pihooks.disable.gms_key_attestation_block >/dev/null 2>&1; then
    su -c setprop persist.sys.pihooks.disable.gms_key_attestation_block true
    su -c setprop persist.sys.pihooks.disable.gms_key_attestation_block true
fi

su -c 'getprop | grep -E "pihook|pixelprops|gms|pi" | sed -E "s/^\[(.*)\]:.*/\1/" | while IFS= read -r prop; do resetprop -p -d "$prop"; done'

# Check if the app is installed
if pm list packages | grep -q "$PACKAGE_NAME"; then
    am force-stop $PACKAGE_NAME
    echo "App $PACKAGE_NAME stopped."
else
    echo "App $PACKAGE_NAME not found."
fi

echo "Done, Reopen detector to check"