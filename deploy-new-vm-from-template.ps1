<#
.SYNOPSIS
    Deploys a new virtual machine from a template.

.DESCRIPTION
    Connects to vCenter, selects a cluster, folder, and datastore with the most free space,
    and deploys a new VM from a specified template.

.PARAMETER VCenterServer
    The vCenter server address.

.PARAMETER VmName
    The name of the new virtual machine.

.PARAMETER TemplateName
    The name of the template to use for deployment.

.PARAMETER ClusterName
    The name of the cluster where the VM should be deployed.

.PARAMETER FolderId
    The ID of the folder where the VM should be located.
#>
[CmdletBinding()]
Param(
    [Parameter(Mandatory=$true)]
    [string]$VCenterServer,

    [Parameter(Mandatory=$true)]
    [string]$VmName,

    [Parameter(Mandatory=$true)]
    [string]$TemplateName,

    [Parameter(Mandatory=$true)]
    [string]$ClusterName,

    [Parameter(Mandatory=$true)]
    [string]$FolderId
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
    # Get Template
    $Template = Get-Template -Name $TemplateName -ErrorAction Stop

    # Select a random host from the cluster
    $Cluster = Get-Cluster -Name $ClusterName | Get-VMHost | Get-Random

    # Get Folder
    $Folder = Get-Folder -Id $FolderId -ErrorAction Stop

    # Select the datastore with the highest free space
    $Datastore = Get-Datastore | Sort-Object FreeSpaceGB -Descending | Select-Object -First 1

    # New Virtual machine details
    Write-Output "Deploying VM $VmName from template $TemplateName..."
    $newVm = New-VM -Name $VmName -Template $Template -VMHost $Cluster -Location $Folder -Datastore $Datastore -DiskStorageFormat Thin -Confirm:$false

    Write-Output "Starting VM $VmName..."
    Start-VM -VM $newVm -Confirm:$false

    # Open Console (This might only work in interactive sessions)
    # Open-VMConsoleWindow -VM $newVm
}
finally {
    if ($connection) {
        Write-Verbose "Disconnecting from vCenter Server..."
        Disconnect-VIServer -Server $connection -Confirm:$false
    }
}
