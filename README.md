# Evil-Collection-2.5
EVIL 2.5 - cross-platform collection of scripts for complete and irreversible destruction of OS, data and bootloader. Supports Windows, Linux, Android (root/no-root), macOS. Result - total device death. For educational purposes only in isolated environment. Responsibility lies with the runner

# EVIL 2.5 - Cross-Platform Destructive Collection

**Warning: These scripts are for educational purposes only in isolated virtual environments. Running on real hardware will cause irreversible data loss, OS destruction, and permanent device damage. The author assumes no responsibility for any damage.**

---

## Platform Capabilities

### Windows 
## What Is EVIL 7 NewGen TOTAL

EVIL 7 NewGen TOTAL is the final, complete, no-compromise version of the EVIL series for Windows. It combines:

- **Network worm** — spreads across local network via SMB/Admin$ + WMI
- **Total wiper** — DoD + Gutmann 26-pass disk wiping + clean all
- **Router killer** — reboot/reset/SPI corrupt on supported devices
- **USB destroyer** — kills USB ports via registry + driver deletion + PnP disable
- **UEFI / ESP / MBR annihilation** — makes system unbootable
- **Registry + kernel + driver deletion** — Windows cannot start
- **Self-deletion + forced shutdown**

**This is the maximum software destruction possible on Windows.**

---

## Full Feature List (77+ functions)

| # | Feature | Details |
|---|---------|---------|
| 1 | **VM detection** | Removes VMware/VirtualBox drivers |
| 2 | **Hidden CPU load** | Fork bomb + calc.exe + WMI stress |
| 3 | **Persistence (6 methods)** | Startup, Documents, ProgramData, schtasks, Run, RunOnce |
| 4 | **Wi-Fi password harvest** | Extracts all saved Wi-Fi passwords (EN/RU) |
| 5 | **Router attack** | Sends reboot/reset to common router web interfaces |
| 6 | **Network scanning** | ICMP scan of /24 subnet |
| 7 | **SMB spread** | Copies itself to \\IP\Admin$ using password bruteforce |
| 8 | **WMI remote execution** | Runs copy on remote machines |
| 9 | **Bluetooth / WWAN kill** | Disables all non-Wi-Fi wireless adapters |
| 10 | **Logs + shadows deletion** | wevtutil + vssadmin + WMI |
| 11 | **Kernel deletion** | ntoskrnl, winload, winresume, hal — queued |
| 12 | **Registry total wipe** | SYSTEM, SOFTWARE, SAM, SECURITY, DEFAULT — 10MB zeros |
| 13 | **MBR killer** | First 512 bytes of PhysicalDrive0 overwritten |
| 14 | **Services disabled** | All non-critical services Start=4 |
| 15 | **50+ drivers destroyed** | disk, partmgr, storahci, stornvme, pci, acpi, ntfs, tcpip, ndis, USBSTOR, USBHUB3, bthport and more |
| 16 | **Full disk wipe (26 patterns)** | DoD 5220.22-M + Gutmann — every sector |
| 17 | **clean all via diskpart** | Complete partition table removal |
| 18 | **Logical drives overwrite** | 500×100MB zero writes to C:/D:/E: |
| 19 | **Mass file deletion** | All .exe, .dll, .sys, .mui, fonts, media, themes — queued |
| 20 | **BCD / UEFI / ESP destruction** | Boot configuration wiped, EFI partition erased, BootOrder corrupted |
| 21 | **Network total block** | All adapters disabled, Wi-Fi profiles deleted, firewall blocks inbound+outbound |
| 22 | **USB total kill** | USBSTOR/USBHUB3/USBXHCI disabled + drivers deleted + PnP disable |
| 23 | **ARP table flood** | Poisoning with fake MAC entries |
| 24 | **USB spread (AutoRun)** | Copies script to removable drives with autorun.inf |
| 25 | **DNS spoof on router** | Attempts to change router DNS to 0.0.0.0 |
| 26 | **Certificate deletion** | Removes all trusted certificates |
| 27 | **WinRE destruction** | Disables recovery environment, deletes WinRE.wim |
| 28 | **Process kill** | Taskkill on all non-system processes |
| 29 | **Network shares deletion** | net share * /delete |
| 30 | **Fake BSOD + memory diagnostic** | Triggers blue screen with custom message |
| 31 | **Windows Update + BITS disabled** | No recovery through updates |
| 32 | **Inode exhaustion** | Fills drives with 1KB files until full |
| 33 | **Random admin password** | Changes Administrator password to random string |
| 34 | **WinRing0 hardware attacks** | MSR write (CPU power), EC port kill (battery/controller) |
| 35 | **ASCII skull + siren** | 666/1000/1337 Hz beeps |
| 36 | **Self-deletion + forced shutdown** | Removes script and powers off |

---

## Irreversible Effects

- **All data on all drives** — permanently destroyed (26-pass overwrite + clean all)
- **Windows cannot boot** — bootloader + kernel + registry eliminated
- **Drives may not be detected** — storage drivers destroyed
- **Network dead** — adapters disabled, firewall locked, Wi-Fi erased
- **USB ports dead** — USBSTOR/USBHUB3 drivers destroyed + PnP disabled
- **Recovery impossible** — logs, shadows, WinRE, certificates deleted
- **Router (partial)** — rebooted/reset (hardware brick on vulnerable models)

---

## Technical Details

| Action | Method | Persistence |
|--------|--------|-------------|
| Disk wipe | 26 patterns × `\\.\PhysicalDriveN` raw write | Permanent |
| Registry kill | 10MB zero overwrite | Permanent |
| MBR kill | 512 bytes raw write | Permanent |
| Kernel delete | `PendingFileRenameOperations` | After reboot |
| Driver kill | Start=4 + `.sys` deletion | After reboot |
| UEFI/ESP kill | `mountvol Z:` + raw write + BootOrder wipe | Permanent |
| Network kill | `Disable-NetAdapter` + `netsh advfirewall block` | Permanent |
| USB kill | Start=4 + driver deletion + `Disable-PnpDevice -Class USB` | After reboot |
| Network spread | `Admin$` copy + WMI + `schtasks` | Remote execution |

---

## Requirements

- **Windows 7 / 8 / 10 / 11** (x64 recommended)
- **Administrator privileges** (script auto-elevates)
- **PowerShell** (any version)
- **Optional:** `WinRing0x64.dll` for hardware attacks (place next to script)


---

## ⚠️ Warning

**This script is for educational (or not:D) purposes only in isolated virtual environments.**

- Data recovery is impossible
- Windows reinstallation requires bootable USB
- Hardware is not physically damaged

### Linux (V-2.5) 
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

### Android Root (V-2.5) 
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

### Android No Root (V-2.5) 
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

### macOS (V-2.5) 
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
3. Run: `.\evil (Windows) NewGen 7.ps1`
or through the desktop

### Linux / macOS
1. Open terminal
2. Make executable: `chmod +x evil_linux_2.5.sh`
3. Run as root: `sudo ./evil_linux_2.5.sh`
or through the desktop

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
