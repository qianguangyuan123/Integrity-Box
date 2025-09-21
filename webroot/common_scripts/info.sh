#!/system/bin/sh
nohup am start -a android.intent.action.VIEW -d https://github.com/MeowDump/Integrity-Box >/dev/null 2>&1 & 
echo "Redirecting to Source Code repo"
exit 0