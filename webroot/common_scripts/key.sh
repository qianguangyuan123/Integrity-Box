#!/system/bin/sh
MODPATH="/data/adb/modules/playintegrityfix"
UPDATEPATH="/data/adb/modules_update/playintegrityfix"

if [ -f "$MODPATH/common_func.sh" ]; then
    . "$MODPATH/common_func.sh"
elif [ -f "$UPDATEPATH/common_func.sh" ]; then
    . "$UPDATEPATH/common_func.sh"
else
    echo "common_func.sh not found in MODPATH or UPDATEPATH"
    exit 1
fi

# Paths & config
mkdir -p "/data/local/tmp"
A="/data/adb"
B="$A/tricky_store"
C="$A/Box-Brain/Integrity-Box-Logs"
D="$C/keybox.log"
E="$(mktemp -p /data/local/tmp)"
F="$B/keybox.xml"
G="$B/keybox.xml.bak"
H="$B/.k"
I="aHR0cHM6Ly9yYXcuZ2l0aHVidXNlcm"
J="NvbnRlbnQuY29tL01lb3dEdW1wL01lb3dEdW1wL3JlZ"
K="nMvaGVhZHMvbWFpbi9OdWxsVm9pZC9"
LOL="TaG9ja1dhdmUudGFy"
L="/data/adb/modules/playintegrityfix/webroot/common_scripts/cleanup.sh"
M="$A/Box-Brain/.cooldown"
N="$C/.verify"
O="/data/adb/modules_update/playintegrityfix/webroot/common_scripts/cleanup.sh"
BAIGAN="https://raw.githubusercontent.com/MeowDump/Integrity-Box/main/DUMP/2FA"

# Cleanup temp files on exit
trap 'rm -f "$E" "$H"' EXIT

log() {
  echo "$*" | tee -a "$D"
}

mkdir -p "$C"
mkdir -p "$B"
touch "$D"

BB=$(P)
log " ✦ Busybox path: $BB"

# Check verification file presence
if [ ! -s "$N" ]; then
  log " ✦ Outdated version detected❌"
  log " ✦ Please use the latest version of module"
  exit 20
fi
log " ✦ Verification file present"

# Download verification file
if [ -n "$BB" ] && "$BB" wget --help >/dev/null 2>&1; then
  log " "
  log " ✦ Fetching verification file"
  "$BB" wget -q --no-check-certificate -O "$E" "$BAIGAN"
elif command -v wget >/dev/null 2>&1; then
  log " ✦ Using system wget to download verification file"
  wget -q --no-check-certificate -O "$E" "$BAIGAN"
elif command -v curl >/dev/null 2>&1; then
  log " ✦ Using curl to download verification file"
  curl -fsSL --insecure "$BAIGAN" -o "$E"
else
  log " ✦ No downloader available, exiting"
  exit 2
fi

if [ ! -s "$E" ]; then
  log " ✦ Failed to fetch remote verification file"
  rm -f "$E"
  exit 21
fi
log " ✦ Processing remote verification"

# Check if local verify matches virtual 
MATCH_FOUND=0
while IFS= read -r local_word; do
  grep -Fxq "$local_word" "$E" && MATCH_FOUND=1 && break
done < "$N"
rm -f "$E"

if [ "$MATCH_FOUND" -ne 1 ]; then
  log " ✦ Access denied, verification mismatch"
  exit 22
fi
log " ✦ Remote verification passed"

# Cooldown check
NOW=$(date +%s)
if [ -f "$M" ]; then
  LAST=$(cat "$M")
  DIFF=$((NOW - LAST))
  if [ "$DIFF" -lt 60 ]; then
    log " ✦ Cooldown active, exiting"
    exit 0
  fi
fi
echo "$NOW" > "$M"
log " "
log " ✦ Cooldown updated"

y "/data/adb/modules/playintegrityfix/webroot/style.css"
y "/data/adb/modules/playintegrityfix/webroot/Flags/index.html"
y "/data/adb/modules/playintegrityfix/module.prop"

# Backup keybox
[ -s "$F" ] && { cp -f "$F" "$G"; log " ✦ Backed up keybox.xml"; }

# Decode URL for keybox download
U=$(printf '%s%s%s%s' "$I" "$J" "$K" "$LOL" | tr -d '\n' | Z)
log " ✦ Decoded keybox download URL"

# Download keybox
if [ -n "$BB" ] && "$BB" wget --help >/dev/null 2>&1; then
  log " "
  log " ✦ Fetching keybox.xml"
  "$BB" wget -q --no-check-certificate -O "$E" "$U"
elif command -v wget >/dev/null 2>&1; then
  log " ✦ Using system wget to download keybox"
  wget -q --no-check-certificate -O "$E" "$U"
elif command -v curl >/dev/null 2>&1; then
  log " ✦ Using curl to download keybox"
  curl -fsSL --insecure "$U" -o "$E"
else
  log " ✦ No downloader available, exiting"
  exit 2
fi

if [ ! -s "$E" ]; then
  log " ✦ Failed to download keybox file"
  rm -f "$E"
  exit 3
fi
log " ✦ Keybox downloaded"

# Decode keybox
for i in $(seq 1 10); do
  T="$(mktemp -p /data/local/tmp)"
  if ! base64 -d "$E" > "$T" 2>/dev/null; then
    log " ✦ Base64 decode failed on iteration $i"
    exit 4
  fi
  rm -f "$E"
  E="$T"
done
log " ✦ Base64 decoding completed"

# Hex decode
if ! xxd -r -p "$E" > "$H" 2>/dev/null; then
  log " ✦ Hex decoding failed"
  exit 5
fi
rm -f "$E"
log " ✦ Hex decoding completed"

# ROT13 decode
if ! tr 'A-Za-z' 'N-ZA-Mn-za-m' < "$H" > "$F"; then
  log " ✦ ROT13 decoding failed"
  rm -f "$H"
  exit 6
fi
rm -f "$H"
log " ✦ ROT13 decoding completed"

# Verify final keybox file
if [ ! -s "$F" ]; then
  log " ✦ Keybox missing or empty, restoring backup if available"
  if [ -s "$G" ]; then
    mv -f "$G" "$F"
    log " ✦ Backup restored"
  fi
  exit 7
fi

log " ✦ Keybox is ready"
log " "

# Clean temporary files
if [ -f "$L" ]; then
  sh "$L" > /dev/null 2>&1
elif [ -f "$O" ]; then
  sh "$O" > /dev/null 2>&1
fi