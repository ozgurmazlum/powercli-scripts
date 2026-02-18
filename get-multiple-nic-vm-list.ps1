<#
.SYNOPSIS
    Lists VMs with more than one network adapter.

.DESCRIPTION
    Connects to vCenter and retrieves a list of VMs that have more than 1 network adapter.

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
    Write-Verbose "Scanning VMs for multiple NICs..."

    # Process VMs. Using a pipeline reduces memory usage compared to storing all in a variable first.
    Get-VM | ForEach-Object {
        $vm = $_
        # Get-NetworkAdapter can be slow per VM, but it is accurate.
        $adapters = $vm | Get-NetworkAdapter
        $nicCount = $adapters.Count

        if ($nicCount -gt 1) {
            [PSCustomObject]@{
                VMName   = $vm.Name
                NicCount = $nicCount
            }
        }
    }
}
finally {
    # Disconnect
    if ($connection) {
        Write-Verbose "Disconnecting..."
        Disconnect-VIServer -Server $connection -Confirm:$false -Force
    }
}
