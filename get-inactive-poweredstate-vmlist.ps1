<#
.SYNOPSIS
    Retrieves a list of PoweredOn VMs with network adapters that are not set to start connected.

.DESCRIPTION
    This script connects to a vCenter server and checks for VMs that are powered on
    but have network adapters where 'StartConnected' is false.

.PARAMETER VCenterServer
    The hostname or IP address of the vCenter server.

.PARAMETER VMNamePattern
    A wildcard pattern to filter VMs by name. Default is '*'.

.EXAMPLE
    .\get-inactive-poweredstate-vmlist.ps1 -VCenterServer "vcenter.example.com"
    .\get-inactive-poweredstate-vmlist.ps1 -VCenterServer "vcenter.example.com" -VMNamePattern "Test-*"
#>
[CmdletBinding()]
Param(
    [Parameter(Mandatory=$true)]
    [string]$VCenterServer,

    [string]$VMNamePattern = "*"
)

# Import PowerCLI module if not already imported
if (-not (Get-Module -Name VMware.PowerCLI -ErrorAction SilentlyContinue)) {
    try {
        Import-Module -Name VMware.PowerCLI -ErrorAction Stop
    }
    catch {
        Write-Error "Failed to import VMware.PowerCLI module. Please ensure it is installed."
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
    Write-Verbose "Retrieving VMs matching pattern '$VMNamePattern'..."

    $vms = Get-VM -Name $VMNamePattern | Where-Object { $_.PowerState -eq "PoweredOn" }

    foreach ($vm in $vms) {
        $adapters = $vm | Get-NetworkAdapter | Where-Object { $_.ConnectionState.StartConnected -eq $false }

        foreach ($adapter in $adapters) {
            [PSCustomObject]@{
                VmName           = $vm.Name
                AdapterName      = $adapter.Name
                StartConnected   = $adapter.ConnectionState.StartConnected
                Connected        = $adapter.ConnectionState.Connected
            }
        }
    }
}
finally {
    # Disconnect from vCenter
    if ($connection) {
        Write-Verbose "Disconnecting from vCenter..."
        Disconnect-VIServer -Server $connection -Confirm:$false -Force
    }
}
