<#
.SYNOPSIS
    Lists hosts and VMs with vFlash Read Cache configured.

.DESCRIPTION
    Connects to vCenter and identifies ESXi hosts and virtual machines that have vFlash Read Cache enabled.

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
        $size = ($server | Get-View).Config.VFlashConfigInfo.VFlashResourceConfigInfo.Capacity
        $sizeGB = $size / 1GB

        if($sizeGB -gt 0){
            $totalhost++
            Write-Output "$($server.Name) Cache Size : $sizeGB GB"
        }
    }
    Write-Host "Toplam $($servers.Count) Sunucudan $($totalhost) tanesinde SSD Cache Tanımlı" -BackgroundColor DarkYellow

    Write-Host "`r`n`r`nSSD vFlash Cache Tanımlı Sanal Sunucular" -ForegroundColor Green

    $vms = Get-VM
    $totalvm = 0

    foreach($vm in $vms){
        $disks = $vm | Get-HardDisk
        $hasCache = $false
        foreach($disk in $disks){
            $cacheSize = $disk.ExtensionData.vFlashCacheConfigInfo.ReservationInMB
            if($cacheSize -gt 0){
                if (-not $hasCache) {
                    $totalvm ++
                    Write-Host "$($vm.Name) ($($vm.VMHost.Name))" -ForegroundColor Cyan
                    $hasCache = $true
                }
                Write-Output "$($disk.Name) Cache Size : $cacheSize MB"
            }
        }
    }
    Write-Host "Toplam $($vms.Count) sanal sunucudan $($totalvm) tanesi üzerinde SSD Cache Tanımlı" -BackgroundColor DarkYellow
}
finally {
    if ($connection) {
        Write-Verbose "Disconnecting..."
        Disconnect-VIServer -Server $connection -Confirm:$false -Force
    }
}
