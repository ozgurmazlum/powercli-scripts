<#
.SYNOPSIS
    Lists hosts and VMs with vFlash Read Cache configured.

.DESCRIPTION
    Connects to vCenter, retrieves all hosts and VMs, and reports those with vFlash Read Cache settings.

.PARAMETER VCenterServer
    The vCenter server address.
#>
[CmdletBinding()]
Param(
    [Parameter(Mandatory=$true)]
    [string]$VCenterServer
)

# Import PowerCLI module if not already imported
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
    Write-Verbose "Connecting to vCenter Server: $VCenterServer"
    $connection = Connect-VIServer -Server $VCenterServer -ErrorAction Stop
}
catch {
    Write-Error "Failed to connect to vCenter Server $VCenterServer. Error: $_"
    exit 1
}

try {
    $servers = Get-VMHost

    Write-Host "Sunucu Bilgileri Alınıyor" -BackgroundColor Red

    Write-Host " - - - SSD vFlash Cache Tanımlı Hostlar - - - " -ForegroundColor White
    $totalhost = 0
    foreach($server in $servers){

        $size = ($server | Get-View).config.VFlashConfigInfo.VFlashResourceConfigInfo.Capacity
        $size = $size / 1GB

        if($size -gt 0){
            $totalhost++
            $server.Name + " Cache Size : " + $size + " GB"
        }
    }

    Write-Host "Toplam $($servers.Count) Sunucudan $($totalhost) tanesinde SSD Cache Tanımlı" -BackgroundColor DarkYellow

    Write-Output "`r`n "
    Write-Output "`r`n "

    Write-Host "SSD vFlash Cache Tanımlı Sanal Sunucular" -ForegroundColor Green

    $vms = Get-VM
    $totalvm = 0

    foreach($vm in $vms){
        $disks = $vm | Get-HardDisk
        $cache = $disks.ExtensionData.vFlashCacheConfigInfo.ReservationInMB

        if($cache -gt 0){
            $totalvm ++
            Write-host $vm.name  $vm.VMHost.Name -ForegroundColor Cyan
            foreach($disk in $disks){
                $cacheSize = $disk.ExtensionData.vFlashCacheConfigInfo.ReservationInMB
                if($cacheSize -gt 0){
                    $disk.Name + " Cache Size : " + $cacheSize
                }
            }
        }
    }

    Write-Host "Toplam $($vms.Count) sanal sunucudan $($totalvm) tanesi üzerinde SSD Cache Tanımlı" -BackgroundColor DarkYellow
}
finally {
    if ($connection) {
        Write-Verbose "Disconnecting from vCenter Server..."
        Disconnect-VIServer -Server $connection -Confirm:$false
    }
}
