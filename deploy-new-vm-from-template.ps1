<#
.SYNOPSIS
    Deploys a new virtual machine from a template.

.DESCRIPTION
    Connects to vCenter and deploys a new VM using the specified template, cluster, and datastore.

.PARAMETER VCenterServer
    The vCenter server address.

.PARAMETER VmName
    The name of the new virtual machine.

.PARAMETER TemplateName
    The name of the template to use for deployment.

.PARAMETER ClusterName
    The name of the cluster where the VM will be deployed.

.PARAMETER DatastorePrefix
    The prefix or name of the datastore where the VM will be stored.
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
    [string]$DatastorePrefix
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
    $template = Get-Template -Name $TemplateName -ErrorAction Stop

    # Select Cluster and a Random Host
    $cluster = Get-Cluster -Name $ClusterName -ErrorAction Stop
    $vmHost = $cluster | Get-VMHost | Get-Random

    # Select Datastore with highest free space matching the prefix
    $datastore = Get-Datastore -Name "$DatastorePrefix*" | Sort-Object FreeSpaceGB -Descending | Select-Object -First 1

    if (-not $datastore) {
        Write-Error "No datastore found matching prefix '$DatastorePrefix'."
        return
    }

    Write-Output "Deploying VM '$VmName' from template '$TemplateName' to host '$($vmHost.Name)' on datastore '$($datastore.Name)'..."

    # New Virtual machine details
    New-VM -Name $VmName -Template $template -VMHost $vmHost -Datastore $datastore -DiskStorageFormat Thin -Confirm:$false

    Start-VM -VM $VmName -Confirm:$false

    # Open-VMConsoleWindow -VM $VmName
}
finally {
    if ($connection) {
        Write-Verbose "Disconnecting..."
        Disconnect-VIServer -Server $connection -Confirm:$false -Force
    }
}
