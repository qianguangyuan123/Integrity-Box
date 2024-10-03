#!/system/bin/sh
# killgms.sh by osm0sis @ xda-developers
#
# Kill the Google Play services DroidGuard process
# (com.google.android.gms.unstable)

if [ "$USER" != "root" -a "$(whoami 2>/dev/null)" != "root" ]; then
  echo "killgms: need root permissions";
  exit 1;
fi;

killall -v com.google.android.gms.unstable;
