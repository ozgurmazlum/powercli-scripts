Import-Module VMware.PowerCLI 

$vcenter = "vcenter.local"
$user = "root"
$pass = "vmware"

Connect-VIServer -Server $vcenter -User $user -Password $pass


$resulth = @()


$datastores = Get-Datastore

foreach ($datastore in $datastores) {
   
    $resulth += $datastore | Select-Object Name,@{N="VMCOUNT";E={($_ | Get-VM).count}},@{N="FREESPACE";E={$_.FreeSpaceGB}}
}


$resulth | sort-object -Property VMCOUNT -Descending | Format-Table -AutoSize


Disconnect-VIServer -Server $vcenter -Confirm:$false
