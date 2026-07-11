<#
.SYNOPSIS
    Searches for PortGroups by VLAN ID.

.DESCRIPTION
    Connects to vCenter and finds virtual switches and VMs associated with a specific VLAN ID.

.PARAMETER VCenterServer
    The vCenter server address.

.PARAMETER VlanId
    The VLAN ID to search for.
#>
[CmdletBinding()]
Param(
    [Parameter(Mandatory=$true)]
    [string]$VCenterServer,

    [Parameter(Mandatory=$true)]
    [int]$VlanId
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
    $switches = Get-VDSwitch | Get-VirtualPortGroup | Select-Object *, @{N="vlanID";E={$_.ExtensionData.Config.DefaultPortConfig.Vlan.VlanId}} | Where-Object { $_.vlanID -eq $VlanId }

    foreach ($switch in $switches) {
        Write-Host -ForegroundColor Green "Virtual Switch Name: $($switch.Name)"
        Write-Host -ForegroundColor Yellow "$($switch.Name): Virtual switch üzerinde çalışan sanal sunucular"
        Get-VirtualPortGroup -Name $switch.Name | Get-VM | Select-Object Name | Format-Table
    }
}
finally {
    if ($connection) {
        Write-Verbose "Disconnecting..."
        Disconnect-VIServer -Server $connection -Confirm:$false -Force
    }
}
