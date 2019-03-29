
# Powershell Gallery PowerCLI modullerini yukluyoyuruz
Import-Module VMware.PowerCLI


Connect-VIServer -Server vcenter ip

clear

$dateTime =  Get-Date -Format dd-MM-yy

$Report = @() 
$start = (Get-Date).AddDays(-1)
$metric = "cpu.ready.summation"

$vms = Get-Cluster  | Get-VM

Get-Stat -Entity $vms -Stat $metric -Start $start | Group-Object -Property {$_.Entity.Name} | %{
  New-Object PSObject -Property @{
    VM = $_.Values[0]
    ReadyAvg = &{
      $interval = $_.Group[0].IntervalSecs * 1000
      $value = $_.Group | Measure-Object -Property Value -Average | Select -ExpandProperty Average
      "{0:p}" -f ($value/$interval)
    }
  }
}
$Report | Export-Csv "C:\Raporlar\$($dateTime + ".txt")" -NoTypeInformation -UseCulture

$Report | Format-Table -AutoSize


Disconnect-VIServer -Server * -Force -Confirm:$false
