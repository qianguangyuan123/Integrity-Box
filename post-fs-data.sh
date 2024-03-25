MODPATH="${0%/*}"
. $MODPATH/common_func.sh

if [ -d "$MODPATH/zygisk" ]; then
    # Remove Play Services from Magisk DenyList when set to Enforce in normal mode
    if magisk --denylist status; then
        magisk --denylist rm com.google.android.gms
    fi
    # Run common tasks for installation and boot-time
    . $MODPATH/common_setup.sh
else
    # Add Play Services DroidGuard process to Magisk DenyList for better results in scripts-only mode
    magisk --denylist add com.google.android.gms com.google.android.gms.unstable
fi

# Conditional early sensitive properties

# Samsung
resetprop_if_diff ro.boot.warranty_bit 0
resetprop_if_diff ro.vendor.boot.warranty_bit 0
resetprop_if_diff ro.vendor.warranty_bit 0
resetprop_if_diff ro.warranty_bit 0

# Xiaomi
resetprop_if_diff ro.secureboot.lockstate locked

# Realme
resetprop_if_diff ro.boot.realmebootstate green

# OnePlus
resetprop_if_diff ro.is_ever_orange 0

# Microsoft
resetprop_if_diff ro.build.tags release-keys

# Other
resetprop_if_diff ro.build.type user
resetprop_if_diff ro.debuggable 0
resetprop_if_diff ro.secure 1
