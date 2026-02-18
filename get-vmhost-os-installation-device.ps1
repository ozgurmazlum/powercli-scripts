<#
.SYNOPSIS
    Retrieves the OS installation device details for ESXi hosts.

.DESCRIPTION
    Connects to vCenter, iterates through hosts, identifies the diagnostic partition disk,
    and returns the storage device details for that disk.

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
    Write-Verbose "Retrieving host storage details..."

    # Use Get-View to batch fetch only necessary properties, avoiding N+1 queries.
    Get-View -ViewType HostSystem -Property Name, Config.DiagnosticPartition, Config.StorageDevice.ScsiLun | ForEach-Object {
        $xHost = $_

        # Get diagnostic partition to identify the OS disk
        # Note: This assumes the diagnostic partition is on the OS disk.
        # Accessing property directly from the View object (Config.DiagnosticPartition)
        $diagPartition = $xHost.Config.DiagnosticPartition

        if ($diagPartition) {
            # HostDiagnosticPartition usually has a single active partition reference
            $diskIdentifier = $diagPartition.Id.DiskName
        } else {
            $diskIdentifier = $null
        }

        if ($diskIdentifier) {
            # Find the ScsiLun matching the disk identifier
            $lun = $xHost.Config.StorageDevice.ScsiLun | Where-Object { $_.CanonicalName -eq $diskIdentifier }

            if ($lun) {
                [PSCustomObject]@{
                    VMHost       = $xHost.Name
                    DisplayName  = $lun.DisplayName
                    Model        = $lun.Model
                    DeviceName   = $lun.DeviceName
                    Vendor       = $lun.Vendor
                    DevicePath   = $lun.DevicePath
                    CanonicalName= $lun.CanonicalName
                }
            } else {
                Write-Warning "Could not find ScsiLun for disk identifier '$diskIdentifier' on host '$($xHost.Name)'."
            }
        } else {
            Write-Warning "No diagnostic partition found on host '$($xHost.Name)'."
        }
    }
}
finally {
    if ($connection) {
        Write-Verbose "Disconnecting..."
        Disconnect-VIServer -Server $connection -Confirm:$false -Force
    }
}
