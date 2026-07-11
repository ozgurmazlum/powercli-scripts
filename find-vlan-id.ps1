<#
.SYNOPSIS
    Finds PortGroups by VLAN ID and lists associated VMs.

.DESCRIPTION
    Connects to vCenter, finds the Distributed Switch PortGroup with the specified VLAN ID,
    and lists the VMs connected to it.

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
    $Switch = Get-VDSwitch | Get-VirtualPortGroup | Select-Object *, @{N="VlanIdFound";E={$_.ExtensionData.Config.DefaultPortConfig.Vlan.VlanId}} | Where-Object { $_.VlanIdFound -eq $VlanId }

    if ($Switch) {
        foreach ($pg in $Switch) {
            Write-Host -ForegroundColor Green "Virtual Switch PortGroup Name: $($pg.Name)"
            Write-Host -ForegroundColor Yellow "$($pg.Name): Virtual switch üzerinde çalışan sanal sunucular"
            Get-VirtualPortGroup -Name $pg.Name | Get-VM | Select-Object Name | Format-Table
        }
    } else {
        Write-Warning "No PortGroup found with VLAN ID $VlanId"
    }
}
finally {
    if ($connection) {
        Write-Verbose "Disconnecting from vCenter Server..."
        Disconnect-VIServer -Server $connection -Confirm:$false
    }
}
