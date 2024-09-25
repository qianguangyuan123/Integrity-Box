MODPATH="${0%/*}"

set +o standalone
unset ASH_STANDALONE
sh $MODPATH/autopif.sh || exit 1

echo -e "\nDone!"
echo -e "\nClosing dialog in 10 seconds ..."
sleep 10
