<#
.SYNOPSIS
    Generates a CPU Ready report for all VMs in clusters.

.DESCRIPTION
    Connects to vCenter, retrieves CPU ready statistics for the last 24 hours, and exports them to a CSV file.

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
    $dateTime = Get-Date -Format "dd-MM-yy"
    $start = (Get-Date).AddDays(-1)
    $metric = "cpu.ready.summation"

    $vms = Get-Cluster | Get-VM

    $Report = Get-Stat -Entity $vms -Stat $metric -Start $start | Group-Object -Property {$_.Entity.Name} | ForEach-Object {
        New-Object PSObject -Property @{
            VM = $_.Values[0]
            ReadyAvg = &{
                $interval = $_.Group[0].IntervalSecs * 1000
                $value = $_.Group | Measure-Object -Property Value -Average | Select-Object -ExpandProperty Average
                "{0:p}" -f ($value/$interval)
            }
        }
    }

    # Use a generic path for the report
    $reportDir = Join-Path $env:USERPROFILE "Desktop"
    $reportPath = Join-Path $reportDir "CPU-Ready-Report-$($dateTime).csv"

    if ($Report) {
        $Report | Export-Csv $reportPath -NoTypeInformation -UseCulture
        $Report | Format-Table -AutoSize
        Write-Output "Report saved to $reportPath"
    } else {
        Write-Warning "No statistics found to report."
    }
}
finally {
    if ($connection) {
        Write-Verbose "Disconnecting..."
        Disconnect-VIServer -Server $connection -Confirm:$false -Force
    }
}
