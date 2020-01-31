#Importing Powershell Gallery PowerCLI Module
 
Import-Module -Name VMware.PowerCLI
 
# Connecting Vcenter Server
Connect-VIServer -Server vcenterip -user your-username -Password password
 
Clear-Host
 
$logPath = "C:\Users\$localUser\Desktop\VmwareToolsUpgradeLog.txt"
 
$vms =  Get-VM | Where-Object {$_.PowerState -eq "PoweredOn" -and $_.ExtensionData.Guest.ToolsVersionStatus -eq "guestToolsNeedUpgrade" -and $_.ExtensionData.Guest.GuestFullName -eq "Microsoft Windows Server 2016 or later (64-bit)"} | select -First 1
 
foreach($vm in $vms){
 
$vm | New-Snapshot -Name "VmwareUpdate-OM" -Memory
 
$vm | Get-Snapshot
 
$vm | Open-VMConsoleWindow -FullScreen
 
$vm | Update-Tools -NoReboot
 
"$vm.name : Vmware Tools Upgraded | $(Get-date)" | Add-Content -Path $logPath
 
 
}
 
#Remove Vm Snapshots
#Get-vm | Get-Snapshot -Name "VmwareUpdate-OM" | Remove-Snapshot -confirm:$false
 
 
Disconnect-VIServer -Server * -Force
