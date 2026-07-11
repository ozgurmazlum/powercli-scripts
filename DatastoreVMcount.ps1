<#
.SYNOPSIS
    Lists VMs count and free space for each datastore.

.DESCRIPTION
    Connects to vCenter and retrieves datastore information including VM count and free space.

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
    $resulth = @()
    $datastores = Get-Datastore
    foreach ($datastore in $datastores) {
        $resulth += $datastore | Select-Object Name,@{N="VMCOUNT";E={($_ | Get-VM).Count}},@{N="FREESPACE";E={$_.FreeSpaceGB}}
    }
    $resulth | Sort-Object -Property VMCOUNT -Descending | Format-Table -AutoSize
}
finally {
    if ($connection) {
        Write-Verbose "Disconnecting..."
        Disconnect-VIServer -Server $connection -Confirm:$false -Force
    }
}
