<#
.SYNOPSIS
    Kills a VM process on an ESXi host using ESXCLI.

.DESCRIPTION
    Connects to vCenter, finds the host where the VM is running, retrieves the World ID,
    and kills the process.

.PARAMETER VCenterServer
    The vCenter server address.

.PARAMETER VMName
    The name of the virtual machine to kill.
#>
[CmdletBinding()]
Param(
    [Parameter(Mandatory=$true)]
    [string]$VCenterServer,

    [Parameter(Mandatory=$true)]
    [string]$VMName
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
    $vm = Get-VM -Name $VMName -ErrorAction Stop
}
catch {
    Write-Error "VM '$VMName' not found on vCenter $VCenterServer."
    Disconnect-VIServer -Server $connection -Confirm:$false -Force
    exit 1
}

try {
    $vmHost = $vm.VMHost
    Write-Verbose "VM '$VMName' is running on host '$($vmHost.Name)'."

    # Use -VMHost to tunnel commands through vCenter (avoids direct host login prompts)
    $esxcli = Get-EsxCli -VMHost $vmHost

    # List processes
    $processList = $esxcli.vm.process.list()

    # Find the process for this VM
    $targetProcess = $processList | Where-Object { $_.DisplayName -eq $vm.Name }

    if ($targetProcess) {
        $worldID = $targetProcess.WorldID
        Write-Warning "Killing process for VM '$VMName' (WorldID: $worldID) on host '$($vmHost.Name)'..."

        # Kill the process (Force)
        $result = $esxcli.vm.process.kill("force", $worldID)

        if ($result -eq $true) {
             Write-Output "Successfully sent kill command for WorldID $worldID."
        } else {
             # EsxCli V1 usually returns true/false or nothing.
             Write-Output "Kill command executed."
        }
    } else {
        Write-Warning "Could not find a running process for VM '$VMName' on host '$($vmHost.Name)'."
    }

}
finally {
    if ($connection) {
        Write-Verbose "Disconnecting..."
        Disconnect-VIServer -Server $connection -Confirm:$false -Force
    }
}
