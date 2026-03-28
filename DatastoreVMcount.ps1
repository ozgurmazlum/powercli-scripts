<#
.SYNOPSIS
    Retrieves VM count and free space for each datastore.

.DESCRIPTION
    Connects to vCenter, iterates through all datastores, and provides a report
    of VM counts and free space.

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

$connection = $null

try {
    Write-Verbose "Connecting to vCenter Server: $VCenterServer"
    # Note: Removed hardcoded root credentials for security.
    # Connect-VIServer will use existing sessions or prompt for credentials if needed.
    $connection = Connect-VIServer -Server $VCenterServer -ErrorAction Stop

    Write-Verbose "Retrieving datastore information..."
    $datastores = Get-Datastore

    # Optimization: Assign loop results directly to variable and use ExtensionData for VM count (N+1 fix)
    $resulth = foreach ($datastore in $datastores) {
        $vmCount = 0
        if ($null -ne $datastore.ExtensionData.Vm) {
            $vmCount = $datastore.ExtensionData.Vm.Count
        }

        $datastore | Select-Object Name,
            @{N="VMCOUNT";E={$vmCount}},
            @{N="FREESPACE";E={$_.FreeSpaceGB}}
    }

    if ($resulth) {
        $resulth | Sort-Object -Property VMCOUNT -Descending | Format-Table -AutoSize
    } else {
        Write-Warning "No datastores found."
    }

}
catch {
    Write-Error "An error occurred: $_"
}
finally {
    if ($null -ne $connection -and $connection.IsConnected) {
        Write-Verbose "Disconnecting from $($connection.Name)..."
        Disconnect-VIServer -Server $connection -Confirm:$false -Force
    }
}
