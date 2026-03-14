<#
.SYNOPSIS
    Automatically upgrades VMware Tools on powered-on Windows VMs.

.DESCRIPTION
    Connects to vCenter, identifies Windows VMs needing a tools upgrade,
    takes a snapshot, and performs the upgrade.

.PARAMETER VCenterServer
    The vCenter server address.

.PARAMETER Username
    The username for vCenter connection.

.PARAMETER Password
    The password for vCenter connection.
#>
[CmdletBinding()]
Param(
    [Parameter(Mandatory=$true)]
    [string]$VCenterServer,

    [Parameter(Mandatory=$false)]
    [string]$Username,

    [Parameter(Mandatory=$false)]
    [string]$Password
)

# Import PowerCLI module
if (-not (Get-Module -Name VMware.PowerCLI -ErrorAction SilentlyContinue)) {
    Import-Module -Name VMware.PowerCLI
}

$connection = $null
try {
    # Connecting Vcenter Server
    $connectArgs = @{
        Server = $VCenterServer
        ErrorAction = "Stop"
    }
    if ($Username) { $connectArgs["User"] = $Username }
    if ($Password) { $connectArgs["Password"] = $Password }

    Write-Verbose "Connecting to vCenter Server: $VCenterServer"
    $connection = Connect-VIServer @connectArgs

    $logPath = Join-Path $env:USERPROFILE "Desktop\VmwareToolsUpgradeLog.txt"

    $vms = Get-VM | Where-Object {
        $_.PowerState -eq "PoweredOn" -and
        $_.ExtensionData.Guest.ToolsVersionStatus -eq "guestToolsNeedUpgrade" -and
        $_.ExtensionData.Guest.GuestFullName -eq "Microsoft Windows Server 2016 or later (64-bit)"
    } | select -First 1

    foreach ($vm in $vms) {
        Write-Host "Upgrading VMware Tools on $($vm.Name)..." -ForegroundColor Cyan

        $vm | New-Snapshot -Name "VmwareUpdate-OM" -Memory -Confirm:$false

        $vm | Get-Snapshot | Out-Null

        # $vm | Open-VMConsoleWindow -FullScreen # This might not be suitable for automated runs, but keeping logic for now

        $vm | Update-Tools -NoReboot

        "$($vm.Name) : Vmware Tools Upgraded | $(Get-Date)" | Add-Content -Path $logPath
    }
}
catch {
    Write-Error "An error occurred: $_"
}
finally {
    if ($connection) {
        Write-Verbose "Disconnecting from vCenter Server"
        Disconnect-VIServer -Server $connection -Confirm:$false -Force
    }
}
