# Powershell Gallery PowerCLI modullerini yukluyoyuruz
[CmdletBinding()]
Param(
    [Parameter(Mandatory=$true)]
    [string]$VCenterServer
)

if (-not (Get-Module -Name VMware.PowerCLI -ErrorAction SilentlyContinue)) {
    try {
        Import-Module -Name VMware.PowerCLI -ErrorAction Stop
    }
    catch {
        Write-Error "Failed to import VMware.PowerCLI module."
        exit 1
    }
}

# Connect to vCenter
try {
    $viServer = Connect-VIServer -Server $VCenterServer -ErrorAction Stop
}
catch {
    Write-Error "Failed to connect to vCenter Server $VCenterServer. Error: $_"
    exit 1
}

clear

Write-Host "Sunucu Bilgileri Alınıyor" -BackgroundColor Red 

Write-Host " - - - SSD vFlash Cache Tanımlı Hostlar - - - " -ForegroundColor White

# Hostları ve vFlash konfigürasyonlarını bir kerede çekiyoruz (N+1 Query optimizasyonu)
$hostViews = Get-View -ViewType HostSystem -Property Name, Config.VFlashConfigInfo
$totalhost = 0
$hostTable = @{} # VM'lerin host adlarını hızlıca bulabilmek için

foreach($hostView in $hostViews){
    $hostTable[$hostView.MoRef.Value] = $hostView.Name

    $size = 0
    if ($hostView.Config.VFlashConfigInfo -and $hostView.Config.VFlashConfigInfo.VFlashResourceConfigInfo) {
        $size = $hostView.Config.VFlashConfigInfo.VFlashResourceConfigInfo.Capacity / 1GB
    }

    if($size -gt 0){
        $totalhost++
        Write-Output ($hostView.Name + " Cache Size : " + $size + " GB")
    }
}

Write-Host "Toplam $($hostViews.Count) Sunucudan $($totalhost) tanesinde SSD Cache Tanımlı" -BackgroundColor DarkYellow

$("`r`n ")
$("`r`n ")

Write-Host "SSD vFlash Cache Tanımlı Sanal Sunucular" -ForegroundColor Green

# VM'leri ve disk konfigürasyonlarını bir kerede çekiyoruz (N+1 Query optimizasyonu)
$vmViews = Get-View -ViewType VirtualMachine -Property Name, Runtime.Host, Config.Hardware.Device
$totalvm = 0

foreach($vmView in $vmViews){
    $disks = $vmView.Config.Hardware.Device | Where-Object { $_ -is [VMware.Vim.VirtualDisk] }

    # Herhangi bir diskte vFlash cache tanımlı mı kontrol ediyoruz
    $hasCache = $false
    $vFlashDisks = @()
    foreach($disk in $disks) {
        if ($disk.VFlashCacheConfigInfo -and $disk.VFlashCacheConfigInfo.ReservationInMB -gt 0) {
            $hasCache = $true
            $vFlashDisks += $disk
        }
    }

    if($hasCache){
        $totalvm ++
        $hostName = $hostTable[$vmView.Runtime.Host.Value]
        Write-host $vmView.Name $hostName -ForegroundColor Cyan

        foreach($disk in $vFlashDisks){
             Write-Output ($disk.DeviceInfo.Label + " Cache Size : " + $disk.VFlashCacheConfigInfo.ReservationInMB)
        }
    }
}


Write-Host "Toplam $($vmViews.Count) sanal sunucudan $($totalvm) tanesi üzerinde SSD Cache Tanımlı" -BackgroundColor DarkYellow


if ($viServer) {
    Disconnect-VIServer -Server $viServer -Confirm:$false
}
