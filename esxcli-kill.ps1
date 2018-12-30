# Powershell Gallery PowerCLI modullerini yukluyoyuruz
Import-Module VMware.PowerCLI


Connect-VIServer -Server vcenterip

$vName =  Read-Host "Vm Adını Yazın"

$vmName = Get-VM -name $vName

$esxcli = Get-EsxCli -Server $($vmName.VMHost.Name)

$esxcli.vm.process.list()

$vmWorldID = ($esxcli.vm.process.list() | Select-Object -Property DisplayName, WorldID | Where-Object -Property DisplayName -EQ "$vmName").WorldID

$esxcli.vm.process.kill("force","$vmWorldID")


Disconnect-VIServer * -Confirm:$false

