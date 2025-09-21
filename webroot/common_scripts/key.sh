#!/system/bin/sh

mkdir -p "/data/local/tmp"
A="/data/adb"
B="$A/tricky_store"
C="$A/Box-Brain/Integrity-Box-Logs"
D="$C/update.log"
E="$(mktemp -p /data/local/tmp)"
F="$B/keybox.xml"
G="$B/keybox.xml.bak"
H="$B/.k"
I="aHR0cHM6Ly9yYXcuZ2l0aHVidXNlcm"
J="NvbnRlbnQuY29tL01lb3dEdW1wL01lb3dEdW1wL3JlZ"
K="nMvaGVhZHMvbWFpbi9OdWxsVm9pZC9"
L="/data/adb/modules/playintegrity/webroot/common_scripts/cleanup.sh"
TFILE="$A/Box-Brain/.cooldown"
AALOO="/data/adb/Box-Brain/Integrity-Box-Logs/.verify"
BAIGAN="https://raw.githubusercontent.com/MeowDump/Integrity-Box/main/DUMP/2FA"
TAMATAR="$(mktemp -p /data/local/tmp)"
LOL="BcnJpdmFsLnRhcg=="

_(){ echo "$1" | tee -a "$D"; }

P(){ for Q in /data/adb/modules/busybox-ndk/system/*/busybox /data/adb/ksu/bin/busybox /data/adb/ap/bin/busybox /data/adb/magisk/busybox; do [ -x "$Q" ] && echo "$Q" && return; done; }

R(){ for S in 8.8.8.8 1.1.1.1; do ping -c1 -W1 $S >/dev/null 2>&1 && return 0; curl -s --max-time 2 http://clients3.google.com/generate_204 >/dev/null && return 0; done; return 1; }

Z(){ b=0; s=0; while IFS= read -r -n1 c; do case "$c" in [A-Z]) v=$(printf '%d' "'$c"); v=$((v - 65));; [a-z]) v=$(printf '%d' "'$c"); v=$((v - 71));; [0-9]) v=$(printf '%d' "'$c"); v=$((v + 4));; '+') v=62;; '/') v=63;; '=') break;; *) continue;; esac; b=$((b << 6 | v)); s=$((s + 6)); if [ "$s" -ge 8 ]; then s=$((s - 8)); o=$(( (b >> s) & 0xFF )); printf \\$(printf '%03o' "$o"); fi; done; }

y() {
  if [ ! -f "$1" ]; then
    reboot recovery
    exit 100
  fi
}

kill_process() {
    TARGET="$1"
    PID=$(pidof "$TARGET")

    if [ -n "$PID" ]; then
        _ "- Found PID(s) for $TARGET: $PID"
        kill -9 $PID
        _ "- Killed $TARGET"
        _ "$TARGET process killed successfully"
    else
        _ "- $TARGET not running"
    fi
}

mkdir -p "$C"
touch "$D"
echo "[$(date '+%Y-%m-%d %H:%M:%S')]" >> "$D"
BB=$(P)

# Check if local verification file exists
if [ ! -s "$AALOO" ]; then
 _ " "
  _ "PLEASE UPDATE THE MODULE TO LATEST VERSION TO UPDATE THE KEYBOX."
  _ "MAKE SURE TO CHECK @MeowDump TELEGRAM CHANNEL's PINNED MESSEGE"
  exit 20
fi

if [ -n "$BB" ] && "$BB" wget --help >/dev/null 2>&1; then
  "$BB" wget -q --no-check-certificate -O "$TAMATAR" "$BAIGAN"
elif command -v wget >/dev/null 2>&1; then
  wget -q --no-check-certificate -O "$TAMATAR" "$BAIGAN"
elif command -v curl >/dev/null 2>&1; then
  curl -fsSL --insecure "$BAIGAN" -o "$TAMATAR"
else
  _ "NO_DL"; _ "No downloader available ❌"; exit 2
fi

# Verify download success
if [ ! -s "$TAMATAR" ]; then
  _ "Failed to fetch remote verify"
  _ "Aborting: Cannot reach server ❌"
  rm -f "$TAMATAR"
  exit 21
fi

# Compare the content
MATCH_FOUND=0
while IFS= read -r local_word; do
  if grep -Fxq "$local_word" "$TAMATAR"; then
    MATCH_FOUND=1
    break
  fi
done < "$AALOO"

rm -f "$TAMATAR"

if [ "$MATCH_FOUND" -ne 1 ]; then
  _ "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  _ "         ⚠️  Access Denied!"
  _ "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  _ "This feature requires the latest version"
  _ "     of the module to run properly."
  _ " "
  _ "📌    Please update the module"
  _ "    search integrity box on Google"
  _ " "
  _ "         🚫 Action aborted."
  _ "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  exit 22
fi

#_ "Module Version: 🌟LATEST"

NOW=$(date +%s)
if [ -f "$TFILE" ]; then
  LAST=$(cat "$TFILE")
  DIFF=$(expr "$NOW" - "$LAST")
  if [ "$DIFF" -lt 60 ]; then
    _ "Clicking rapidly won't fix your problem bro😹"
    exit 0
  fi
fi
echo "$NOW" > "$TFILE"

y "/data/adb/modules/playintegrity/webroot/style.css"
y "/data/adb/modules/playintegrity/webroot/Flags/mona.ttf"
y "/data/adb/Box-Brain/Integrity-Box-Logs/Installation.log"

R || { _ "FAIL_NET"; _ "Download failed"; exit 1; }

#_ "Fetching keybox.. please wait"
#_ "BB=$BB"

[ -s "$F" ] && cp -f "$F" "$G"

U=$(printf '%s%s%s' "$I" "$J" "$K" "$LOL" | tr -d '\n' | Z)

if [ -n "$BB" ] && "$BB" wget --help >/dev/null 2>&1; then
  "$BB" wget -q --no-check-certificate -O "$E" "$U"
elif command -v wget >/dev/null 2>&1; then
  wget -q --no-check-certificate -O "$E" "$U"
elif command -v curl >/dev/null 2>&1; then
  curl -fsSL --insecure "$U" -o "$E"
else
  _ "NO_DL"; _ "Download failed"; exit 2
fi

[ -s "$E" ] || { _ "EMPTY"; _ "PLEASE UPDATE THE MODULE, CHECK TELEGRAM CHANNEL"; rm -f "$E"; exit 3; }

i=0
while [ "$i" -lt 10 ]; do
  T="$(mktemp -p /data/local/tmp)"
  base64 -d "$E" > "$T" 2>/dev/null || { _ "B64_FAIL"; _ "Download failed"; exit 4; }
  rm -f "$E"
  E="$T"
  i=$((i + 1))
done

xxd -r -p "$E" > "$H" 2>/dev/null || { _ "HEX_FAIL"; _ "Download failed"; exit 5; }
rm -f "$E"

tr 'A-Za-z' 'N-ZA-Mn-za-m' < "$H" > "$F" || { _ "ROT13_FAIL"; _ "Download failed"; rm -f "$H"; exit 6; }
rm -f "$H"

[ -s "$F" ] || { _ "MISSING"; _ "Please update the module 🚨"; [ -s "$G" ] && mv -f "$G" "$F"; exit 7; }

sh "$L"