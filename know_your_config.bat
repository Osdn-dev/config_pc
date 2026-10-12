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
$lines += "===== CONFIG PC ====="
$lines += ""
$lines += "PROCESSEUR  : " + $cpu.Name.Trim()
$lines += "Coeurs / threads : " + $cpu.NumberOfCores + " / " + $cpu.NumberOfLogicalProcessors
$lines += ""

$marques = @{
    '19DA'='ZOTAC'; '1462'='MSI'; '1043'='ASUS'; '1458'='GIGABYTE'; '3842'='EVGA';
    '196E'='PNY'; '1569'='Palit'; '10B0'='Gainward'; '1DA2'='Sapphire'; '1682'='XFX';
    '148C'='PowerColor'; '1849'='ASRock'; '7377'='Colorful'; '1B4C'='KFA2 / Galax';
    '10DE'='NVIDIA (Founders Edition)'
}
$classKey = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}'
$regGpus = Get-ChildItem $classKey | ForEach-Object { Get-ItemProperty $_.PSPath } | Where-Object { $_.DriverDesc }

foreach ($g in $gpus) {
    $marque = "inconnue"
    if ($g.PNPDeviceID -match 'SUBSYS_([0-9A-F]{4})([0-9A-F]{4})') {
        $code = $Matches[2]
        if ($marques.ContainsKey($code)) { $marque = $marques[$code] } else { $marque = "inconnue (code $code)" }
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

    $lines += "CARTE GRAPHIQUE : " + $g.Name + " (" + $vram + " Go)"
    $lines += "Marque : " + $marque
    $lines += "Driver : " + $g.DriverVersion
}
$lines += ""

$totalRam = [math]::Round(($rams | Measure-Object Capacity -Sum).Sum / 1GB)
$lines += "RAM TOTALE  : $totalRam Go"
$ramMarques = @(
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
    $taille = [math]::Round($r.Capacity / 1GB)
    $fab = "" + $r.Manufacturer
    $fab = $fab.Trim()
    $pn = "" + $r.PartNumber
    $pn = $pn.Trim()
    $marqueRam = $null
    foreach ($m in $ramMarques) {
        if ($pn -match $m[0]) { $marqueRam = $m[1]; break }
    }
    if (-not $marqueRam) {
        if ($fab -and $fab -notmatch 'Unknown|Undefined|^0+$') { $marqueRam = $fab } else { $marqueRam = "marque inconnue" }
    }
    $lines += "  - $taille Go, $($r.Speed) MHz, $marqueRam, $pn"
}
$lines += ""

$lines += "CARTE MERE  : " + $board.Manufacturer + " " + $board.Product
$lines += "BIOS        : " + $bios.SMBIOSBIOSVersion + " (" + $bios.Manufacturer + ")"
$lines += ""

$lines += "STOCKAGE :"
foreach ($d in $disks) {
    $taille = [math]::Round($d.Size / 1GB)
    $lines += "  - " + $d.Model + " (" + $taille + " Go)"
}
$lines += ""

$lines += "SYSTEME     : " + $os.Caption + " (build " + $os.BuildNumber + ")"
$lines += "Modele PC   : " + $sys.Manufacturer + " " + $sys.Model
$lines += ""
$lines += "===== FIN ====="

$texte = $lines -join "`r`n"
$bureau = [Environment]::GetFolderPath('Desktop')
$fichier = Join-Path $bureau "config_pc.txt"
$texte | Out-File -FilePath $fichier -Encoding utf8
$texte | Set-Clipboard

Write-Host ""
Write-Host $texte
Write-Host ""
Write-Host "Termine. La config est copiee dans le presse-papiers (Ctrl+V)."
Write-Host "Elle est aussi sauvegardee sur le Bureau : config_pc.txt"
Write-Host ""
Read-Host "Appuie sur Entree pour fermer"