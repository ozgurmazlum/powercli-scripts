<#
.SYNOPSIS
    Identifies VMs where the configured Guest OS type does not match the actual installed Guest OS.

.DESCRIPTION
    Connects to vCenter and compares the configured Guest ID with the actual Guest ID reported by VMware Tools.

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
    $reportPath = Join-Path $env:USERPROFILE "Desktop\correct-ostype.csv"

    Get-VM | Get-View | Where-Object {$_.Guest.GuestId -and $_.Guest.GuestId -ne $_.Config.GuestId} |
    Select-Object -Property Name,
        @{N="GuestId";E={$_.Guest.GuestId}},
        @{N="Installed Guest OS";E={$_.Guest.GuestFullName}},
        @{N="Configured GuestId";E={$_.Config.GuestId}},
        @{N="Configured Guest OS";E={$_.Config.GuestFullName}} |
    Export-Csv -Path $reportPath -NoTypeInformation

    Write-Output "Report exported to $reportPath"
}
finally {
    if ($connection) {
        Write-Verbose "Disconnecting..."
        Disconnect-VIServer -Server $connection -Confirm:$false -Force
    }
}
