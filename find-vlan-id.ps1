# Powershell Gallery PowerCLI modullerini yukluyoruz
Import-Module VMware.PowerCLI

#userName değişkeni içerisine login olan kullanıcı adımızı alıyoruz
$userName = $env:UserName


$vcenterIP = Read-Host "Vcenter IP Adresiniz"


# VCenter sunucuya erisim sagliyoruz
Connect-VIServer -Server $vcenterIP

clear

$vlanID = Read-Host -Prompt "Vland ID Giriniz"


$Switch = Get-VDSwitch | Get-VirtualPortGroup | Select *, @{N="vlanID";E={$_.Extensiondata.Config.DefaultPortCOnfig.Vlan.VlanId}} | Where VLANId -EQ $vlanID

Write-Host -ForegroundColor Green "Virual Switch Name :" + $Switch.Name

Write-Host -ForegroundColor Yellow $Switch.Name + ": Virtual switch üzerinde çalışan sanal sunucular"
Get-VirtualPortGroup -Name $Switch.Name | Get-VM | Select Name | Format-Table


Disconnect-VIServer -Server * -Force -Confirm:$false