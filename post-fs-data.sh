#!/system/bin/sh

MODPATH="${0%/*}"
MODNAME="${MODPATH##*/}"
MAGISKTMP="$(magisk --path)" || MAGISKTMP=/sbin

if [ "$(magisk -V)" -lt 26302 ] || [ "$(/data/adb/ksud -V)" -lt 10818 ]; then
    touch "$MODPATH/disable"
fi

# Using util_functions.sh
[ -f "$MODPATH/util_functions.sh" ] && . "$MODPATH/util_functions.sh" || abort "! util_functions.sh not found!"

# Set vbmeta verifiedBootHash from file (if present and not empty)
BOOT_HASH_FILE="/data/adb/boot_hash"
if [ -s "$BOOT_HASH_FILE" ]; then
    force_resetprop ro.boot.vbmeta.digest "$(tr '[:upper:]' '[:lower:]' <"$BOOT_HASH_FILE")"
else
    ## force_resetprop ro.boot.vbmeta.digest - insert it manually
fi

# Cleanup and replacements (avoiding duplicates with service.sh)
for prop in $(getprop | grep -E "aosp_|test-keys" | cut -d ":" -f 1 | tr -d '[]'); do
    replace_value_resetprop "$prop" "aosp_" ""
    replace_value_resetprop "$prop" "test-keys" "release-keys"
done

# Process prefixes (optimized to avoid redundant checks)
for prefix in system vendor system_ext product oem odm vendor_dlkm odm_dlkm bootimage; do
    # Check and reset properties only once per prefix
    check_resetprop "ro.${prefix}.build.tags" release-keys
    check_resetprop "ro.${prefix}.build.type" user

    # Replace values in all relevant properties
    for prop in ro.${prefix}.build.description ro.${prefix}.build.fingerprint ro.product.${prefix}.name; do
        replace_value_resetprop "$prop" "aosp_" ""
    done
done
