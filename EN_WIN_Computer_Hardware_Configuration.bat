@echo off
powershell -NoProfile -ExecutionPolicy Bypass -Command "iex ((Get-Content -LiteralPath '%~f0' -Raw) -split ('#PS_'+'START'))[1]"
exit /b
#PS_START
$ErrorActionPreference = 'SilentlyContinue'

$cpu   = Get-CimInstance Win32_Processor | Select-Object -First 1
$gpus  = Get-CimInstance Win32_VideoController
$rams  = Get-CimInstance Win32_PhysicalMemory
$board = Get-CimInstance Win32_BaseBoard
$bios  = Get-CimInstance Win32_BIOS
$os    = Get-CimInstance Win32_OperatingSystem
$disks = Get-CimInstance Win32_DiskDrive
$sys   = Get-CimInstance Win32_ComputerSystem

$lines = @()
$lines += "===== PC CONFIG ====="
$lines += ""
$lines += "PROCESSOR   : " + $cpu.Name.Trim()
$lines += "Cores / threads : " + $cpu.NumberOfCores + " / " + $cpu.NumberOfLogicalProcessors
$lines += ""

$brands = @{
    '19DA'='ZOTAC'; '1462'='MSI'; '1043'='ASUS'; '1458'='GIGABYTE'; '3842'='EVGA';
    '196E'='PNY'; '1569'='Palit'; '10B0'='Gainward'; '1DA2'='Sapphire'; '1682'='XFX';
    '148C'='PowerColor'; '1849'='ASRock'; '7377'='Colorful'; '1B4C'='KFA2 / Galax';
    '10DE'='NVIDIA (Founders Edition)'
}
$classKey = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}'
$regGpus = Get-ChildItem $classKey | ForEach-Object { Get-ItemProperty $_.PSPath } | Where-Object { $_.DriverDesc }

foreach ($g in $gpus) {
    $brand = "unknown"
    if ($g.PNPDeviceID -match 'SUBSYS_([0-9A-F]{4})([0-9A-F]{4})') {
        $code = $Matches[2]
        if ($brands.ContainsKey($code)) { $brand = $brands[$code] } else { $brand = "unknown (code $code)" }
    }

    $vram = $null
    $reg = $regGpus | Where-Object { $_.DriverDesc -eq $g.Name } | Select-Object -First 1
    $q = $reg.'HardwareInformation.qwMemorySize'
    if ($q) {
        if ($q -is [byte[]]) {
            $pad = New-Object byte[] 8
            [Array]::Copy($q, $pad, [Math]::Min(8, $q.Length))
            $q = [BitConverter]::ToUInt64($pad, 0)
        }
        $vram = [math]::Round([double]$q / 1GB)
    }
    if (-not $vram) {
        $smi = & nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits 2>$null
        if ($smi) { $vram = [math]::Round([double]($smi | Select-Object -First 1) / 1024) }
    }
    if (-not $vram) { $vram = "?" }

    $lines += "GRAPHICS CARD : " + $g.Name + " (" + $vram + " GB)"
    $lines += "Brand : " + $brand
    $lines += "Driver : " + $g.DriverVersion
}
$lines += ""

$totalRam = [math]::Round(($rams | Measure-Object Capacity -Sum).Sum / 1GB)
$lines += "TOTAL RAM   : $totalRam GB"
$ramBrands = @(
    @('^CM',                      'Corsair'),
    @('^F[45]-',                  'G.Skill'),
    @('^(KF|KVR|KHX|HX)',         'Kingston'),
    @('^(CT|BL)',                 'Crucial'),
    @('^(TF|TED|TLZ|TPD|TLD|TXD)', 'TeamGroup'),
    @('^(AX|AD)[0-9]',            'ADATA'),
    @('^(PV|PS|VP)',              'Patriot'),
    @('^(M378|M471|M391)',        'Samsung'),
    @('^(HMA|HMT|HMC)',           'SK Hynix'),
    @('^MT',                      'Micron')
)
foreach ($r in $rams) {
    $size = [math]::Round($r.Capacity / 1GB)
    $maker = "" + $r.Manufacturer
    $maker = $maker.Trim()
    $pn = "" + $r.PartNumber
    $pn = $pn.Trim()
    $ramBrand = $null
    foreach ($m in $ramBrands) {
        if ($pn -match $m[0]) { $ramBrand = $m[1]; break }
    }
    if (-not $ramBrand) {
        if ($maker -and $maker -notmatch 'Unknown|Undefined|^0+$') { $ramBrand = $maker } else { $ramBrand = "unknown brand" }
    }
    $lines += "  - $size GB, $($r.Speed) MHz, $ramBrand, $pn"
}
$lines += ""

$lines += "MOTHERBOARD : " + $board.Manufacturer + " " + $board.Product
$lines += "BIOS        : " + $bios.SMBIOSBIOSVersion + " (" + $bios.Manufacturer + ")"
$lines += ""

$lines += "STORAGE :"
foreach ($d in $disks) {
    $size = [math]::Round($d.Size / 1GB)
    $lines += "  - " + $d.Model + " (" + $size + " GB)"
}
$lines += ""

$lines += "SYSTEM      : " + $os.Caption + " (build " + $os.BuildNumber + ")"
$lines += "PC model    : " + $sys.Manufacturer + " " + $sys.Model
$lines += ""
$lines += "===== END ====="

$text = $lines -join "`r`n"
$file = Join-Path (Get-Location).Path "pc_config.txt"
$text | Out-File -FilePath $file -Encoding utf8
$text | Set-Clipboard

Write-Host ""
Write-Host $text
Write-Host ""
Write-Host "Done. The config has been copied to your clipboard (Ctrl+V)."
Write-Host "It is also saved in the current folder as pc_config.txt"
Write-Host ""
Read-Host "Press Enter to close"