# log file path and output file path
L="/data/adb/Box-Brain/Integrity-Box-Logs/sus.log"
O="/data/adb/susfs4ksu/sus_path.txt"


# Logger
meow() {
    echo "$1" | tee -a "$L"
}

touch "$L"

# If file doesn't exist, notify and exit
if [ ! -f "$O" ]; then
  meow "susfs isn't installed ❌"
  exit 1
fi

chmod 644 "$O" "$L"

echo "----------------------------------------------------------" >> "$L"
echo "Logged on $(date '+%A %d/%m/%Y %I:%M:%S%p')" >> "$L"
echo "----------------------------------------------------------" >> "$L"
echo " " >> "$L"

# Check if the output file is writable
if [ ! -w "$O" ]; then
    meow "- $O is not writable. Please check file permissions."
    exit 1
fi

# Log the start of the process
meow "- Adding necessary paths to sus list"
meow " "
> "$O"

# Add paths manually
for path in \
    "/system/addon.d" \
    "/sdcard/TWRP" \
    "/sdcard/Fox" \
    "/vendor/bin/install-recovery.sh" \
    "/system/bin/install-recovery.sh"; do
    echo "$path" >> "$O"
    meow "- Path added: $path"
done

meow "- saved to sus list"
meow " "

# Prepare for scanning
meow "- Scanning system for Custom ROM detection.."

# Search for traces in the specified directories
for dir in /system /product /data /vendor /etc /root; do
    meow "- Searching in: $dir... "
    find "$dir" -type f 2>/dev/null | grep -i -E "lineageos|crdroid|gapps|evolution|magisk" >> "$O"
done

meow " "
meow " "
cat "$O"
meow " "
meow " "

chmod 644 "$O"
meow "- Scan complete. & saved to sus list "
meow " "
exit 0