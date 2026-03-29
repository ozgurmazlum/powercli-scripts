[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$VCenterServer = "vcenter.local",

    [Parameter(Mandatory=$false)]
    [string]$User = "root",

    [Parameter(Mandatory=$false)]
    [string]$Password = "vmware"
)

Import-Module VMware.PowerCLI -ErrorAction SilentlyContinue

try {
    # Connect to vCenter
    $server = Connect-VIServer -Server $VCenterServer -User $User -Password $Password -ErrorAction Stop

    $datastores = Get-Datastore

    # Optimized loop:
    # 1. Use direct variable assignment instead of += (array resizing is slow)
    # 2. Use .ExtensionData.Vm.Count instead of Get-VM (avoids N+1 API calls)
    $resulth = foreach ($datastore in $datastores) {
        $vmCount = if ($datastore.ExtensionData.Vm) { $datastore.ExtensionData.Vm.Count } else { 0 }

        [PSCustomObject]@{
            Name      = $datastore.Name
            VMCOUNT   = $vmCount
            FREESPACE = $datastore.FreeSpaceGB
        }
    }

    $resulth | Sort-Object -Property VMCOUNT -Descending | Format-Table -AutoSize
}
catch {
    Write-Error "An error occurred: $_"
}
finally {
    # Disconnect from vCenter
    if ($server) {
        Disconnect-VIServer -Server $server -Confirm:$false
    }
}
