#Importing Powershell Gallery PowerCLI Module

Import-Module -Name VMware.PowerCLI


# Connecting Vcenter Server
Connect-VIServer 
Clear-Host

(Get-vm ozgur* | Get-NetworkAdapter).ConnectionState | fl *

Get-vm |Where PowerState -EQ "PoweredOn" | Get-NetworkAdapter | Select @{Name="VmName";E={$_.Parent}},ConnectionState | Where {$_.ConnectionState.StartConnected -eq $false} 
 
 #Disconnet All vcenter or hosts
Disconnect-VIServer -Server * -Force -Confirm:$false 
