# Powershell Gallery PowerCLI modullerini yukluyoyuruz
Import-Module VMware.PowerCLI

Connect-VIServer -Server 

clear

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
    #$server.Name + " Flash Cache Var"
    #$size
    
    }
}

Write-Host "Toplam $($servers.Count) Sunucudan $($totalhost) tanesinde SSD Cache Tanımlı" -BackgroundColor DarkYellow

$("`r`n ")
$("`r`n ")

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


Disconnect-VIServer * -Confirm:$false