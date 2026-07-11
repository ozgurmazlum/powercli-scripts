<#
.SYNOPSIS
    Upgrades VMware Tools on powered-on Windows 2016+ VMs.

.DESCRIPTION
    Connects to vCenter, finds VMs that need VMware Tools upgrade, takes a snapshot, and starts the upgrade.

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
    $logPath = Join-Path $env:USERPROFILE "Desktop\VmwareToolsUpgradeLog.txt"

    $vms = Get-VM | Where-Object {
        $_.PowerState -eq "PoweredOn" -and
        $_.ExtensionData.Guest.ToolsVersionStatus -eq "guestToolsNeedUpgrade" -and
        $_.ExtensionData.Guest.GuestFullName -match "Microsoft Windows Server 2016 or later"
    } | Select-Object -First 1

    foreach ($vm in $vms) {
        Write-Verbose "Processing VM: $($vm.Name)"
        $vm | New-Snapshot -Name "VmwareUpdate-OM" -Memory
        $vm | Get-Snapshot
        $vm | Open-VMConsoleWindow -FullScreen
        $vm | Update-Tools -NoReboot
        "$($vm.Name) : Vmware Tools Upgraded | $(Get-Date)" | Add-Content -Path $logPath
    }
}
finally {
    if ($connection) {
        Write-Verbose "Disconnecting..."
        Disconnect-VIServer -Server $connection -Confirm:$false -Force
    }
}
