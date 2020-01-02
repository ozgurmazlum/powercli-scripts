# Powershell Gallery PowerCLI modullerini yukluyoyuruz
Import-Module VMware.PowerCLI

Connect-VIServer -Server

clear

$vname = Read-Host "Vm Adını yazınız"

$vmName = Get-VM $vname

$vmHOST = $vmName | Get-VMHost

$y = $vmName | Get-Stat -Stat cpu.usage.average -Realtime | Where-Object -Property Instance -eq "" | measure Value -Average -Minimum -Maximum

$x = $vmHOST | Get-Stat -Stat cpu.usage.average -Realtime | Where-Object -Property Instance -eq "" | measure Value -Average -Minimum -Maximum

$HostCpuAverage = [math]::Round($x.Average)
$HostCpuMax = [math]::Round($x.Maximum)

$VmCpuAverage = [math]::Round($y.Average)

$VmCpuMax = [math]::Round($y.Maximum)

Write-Host
Write-Host
Write-Host "Guest CPU Bilgileri kontrol Ediliyor" -ForegroundColor Cyan
Write-Host
Write-Host

if($VmCpuAverage -gt 75 -or $VmCpuMax -gt 90){


Write-Host ----------Sanal Sunucu CPU  Değerleri Yüksek !!! ----------- -foregroundcolor White -BackgroundColor DarkRed
Write-Host "VM Name : $vmName.Name"
Write-Host "VM Cpu Average % : $VmCpuAverage"
Write-Host "VM Cpu Max % :  $VmCpuMax"
Write-Host ---------/Sanal Sunucu CPU Kullanım Bilgileri--------------- -foregroundcolor White -BackgroundColor DarkRed
Write-Host

}else{

Write-Host ----------Sanal Sunucu CPU  Değerleri Normal ----------- -foregroundcolor White -BackgroundColor DarkGreen
Write-Host "VM Name : $vmName.Name"
Write-Host "VM Cpu Average % : $VmCpuAverage"
Write-Host "VM Cpu Max % :  $VmCpuMax"
Write-Host ---------/Sanal Sunucu CPU Kullanım Bilgileri--------------- -foregroundcolor White -BackgroundColor DarkGreen
Write-Host

}

Write-Host
Write-Host
Write-Host "Host CPU Bilgileri kontrol Ediliyor" -ForegroundColor Cyan
Write-Host

if($HostCpuAverage -gt 75 -or $HostCpuMax -gt 90){


Write-Host ----------HOST CPU Değerleri Yüksek !!! ----------- -foregroundcolor White -BackgroundColor DarkRed
Write-Host "VM Name : $vmHOST.Name"
Write-Host "Host Cpu Average % :  $HostCpuAverage"
Write-Host "Host Cpu Max % : :  $HostCpuMax"
Write-Host ---------/HOST CPU Kullanım Bilgileri--------------- -foregroundcolor White -BackgroundColor DarkRed
Write-Host


}else{

Write-Host ----------HOST CPU Değerleri Normal ----------- -foregroundcolor White -BackgroundColor Green
Write-Host "VM Name : $vmName.Name"
Write-Host "VM Cpu Average % : $HostCpuAverage"
Write-Host "VM Cpu Max % :  $HostCpuMax"
Write-Host ---------/HOST CPU Kullanım Bilgileri--------------- -foregroundcolor White -BackgroundColor Green
Write-Host

Write-Host
Write-Host -ForegroundColor Cyan $("CPU Ready Kontrol Ediliyor.")

$cpuReady = $vmName | Get-Stat -Stat cpu.ready.summation -Realtime | Where-Object -Property Instance -eq "" | measure Value -Average -Minimum -Maximum

$cpuReadyTimeAverage = [math]::Round($cpuReady.Average)
Write-Host


if($cpuReadyTimeAverage -gt 2000){


Write-Host ----------CPU Ready Time Yüksek ----------- -foregroundcolor White -BackgroundColor Red
Write-Host "VM Name : $vmName.Name"
Write-Host "CPU Ready Time : $cpuReadyTimeAverage"
Write-Host ---------/CPU Ready Time Bilgileri--------------- -foregroundcolor White -BackgroundColor Red
Write-Host

}else{



Write-Host ----------CPU Ready Time Normal ----------- -foregroundcolor White -BackgroundColor Green
Write-Host "VM Name : $vmName.Name"
Write-Host "CPU Ready Time : $cpuReadyTimeAverage"
Write-Host ---------/CPU Ready Time Bilgileri--------------- -foregroundcolor White -BackgroundColor Green
Write-Host


}

}

Disconnect-VIServer -Server * -Force -Confirm:$false
