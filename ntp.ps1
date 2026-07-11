<#
.SYNOPSIS
    Configures NTP servers on all ESXi hosts.

.DESCRIPTION
    Connects to vCenter and ensures that the specified NTP server is configured on all hosts.

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
    Get-VMHost | Get-VmHostService | Where-Object {$_.key -eq "ntpd"}

    $currentNtp = "tr.pool.ntp.org"

    $xVmHosts = Get-VMHost | Sort-Object Name

    foreach ($xVmHost in $xVmHosts) {
        $xNtpServers = $xVmHost | Get-VMHostNtpServer
        if ($xNtpServers.Count -eq 0) {
            $xVmHost | Add-VMHostNtpServer -NtpServer $currentNtp
        } else {
            $xNtpServers | ForEach-Object {
                if ($_.NtpServer -eq $currentNtp) {
                    $_.Remove()
                }
            }
            $xVmHost | Add-VMHostNtpServer -NtpServer $currentNtp
        }
    }
}
finally {
    if ($connection) {
        Write-Verbose "Disconnecting..."
        Disconnect-VIServer -Server $connection -Confirm:$false -Force
    }
}
