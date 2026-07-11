
# benchmark.ps1

# Mock the VMware PowerCLI cmdlets

function Get-Module {
    [CmdletBinding()]
    param($Name, $ErrorAction)
    Write-Verbose "Mock Get-Module for $Name"
    return $true # Pretend module is loaded
}

function Import-Module {
    [CmdletBinding()]
    param($Name, $ErrorAction)
    Write-Verbose "Mock Import-Module for $Name"
}

function Connect-VIServer {
    [CmdletBinding()]
    param($Server)
    Write-Verbose "Mock Connect-VIServer to $Server"
    return [PSCustomObject]@{ Name = $Server }
}

function Disconnect-VIServer {
    [CmdletBinding()]
    param($Server, $Confirm, $Force)
    Write-Verbose "Mock Disconnect-VIServer from $Server"
}

# Mock VM object structure
# We will create a few VMs, some with 1 NIC, some with 2.
# We include both ExtensionData (for Get-VM simulation) and Config (for Get-View simulation)
$config1 = [PSCustomObject]@{
    Hardware = [PSCustomObject]@{
        Device = @(
            [PSCustomObject]@{
                Key = 4000;
                Backing = [PSCustomObject]@{ Type = "VirtualEthernetCard" };
                PSTypeNames = [System.Collections.Generic.List[string]]@("VMware.Vim.VirtualEthernetCard")
            }
        )
    }
}
$vm1 = [PSCustomObject]@{
    Name = "VM1";
    ExtensionData = [PSCustomObject]@{ Config = $config1 }
    Config = $config1
}

$config2 = [PSCustomObject]@{
    Hardware = [PSCustomObject]@{
        Device = @(
            [PSCustomObject]@{
                Key = 4000;
                Backing = [PSCustomObject]@{ Type = "VirtualEthernetCard" };
                PSTypeNames = [System.Collections.Generic.List[string]]@("VMware.Vim.VirtualEthernetCard")
            },
            [PSCustomObject]@{
                Key = 4001;
                Backing = [PSCustomObject]@{ Type = "VirtualEthernetCard" };
                PSTypeNames = [System.Collections.Generic.List[string]]@("VMware.Vim.VirtualEthernetCard")
            }
        )
    }
}
$vm2 = [PSCustomObject]@{
    Name = "VM2";
    ExtensionData = [PSCustomObject]@{ Config = $config2 }
    Config = $config2
}

$config3 = [PSCustomObject]@{
    Hardware = [PSCustomObject]@{
        Device = @(
            [PSCustomObject]@{
                Key = 1000;
                Backing = [PSCustomObject]@{ Type = "VirtualDisk" };
                PSTypeNames = [System.Collections.Generic.List[string]]@("VMware.Vim.VirtualDisk")
            }
        )
    }
}
$vm3 = [PSCustomObject]@{
    Name = "VM3";
    ExtensionData = [PSCustomObject]@{ Config = $config3 }
    Config = $config3
}


$mockVMs = @($vm1, $vm2, $vm3)

# Expand the list to simulate load
$mockVMs = $mockVMs * 10 # 30 VMs total

function Get-VM {
    [CmdletBinding()]
    param()
    Write-Verbose "Mock Get-VM returning $($mockVMs.Count) VMs"
    return $mockVMs
}

function Get-NetworkAdapter {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline=$true)]
        $InputObject
    )
    process {
        Start-Sleep -Milliseconds 10 # Simulate network latency per call
        # Access the device list from the input object
        if ($InputObject.ExtensionData.Config.Hardware.Device) {
             # We simulate finding adapters by checking "PSTypeNames"
             $adapters = @()
             foreach ($device in $InputObject.ExtensionData.Config.Hardware.Device) {
                 if ($device.PSTypeNames -contains "VMware.Vim.VirtualEthernetCard") {
                     $adapters += $device
                 }
             }
             return $adapters
        }
    }
}

function Get-View {
    [CmdletBinding()]
    param($ViewType, $Property)
    Write-Verbose "Mock Get-View for $ViewType"
    # Return the mock VMs directly as they have the structure we need
    return $mockVMs
}

$scriptPath = ".\get-multiple-nic-vm-list.ps1"

Write-Host "Running benchmark for original implementation..."
$sw = [System.Diagnostics.Stopwatch]::StartNew()

# Run the script
# We need to make sure the mocked functions are available to the script.
# Dot sourcing the script runs it in the current scope.
. $scriptPath -VCenterServer "dummy-vcenter"

$sw.Stop()
Write-Host "Execution Time: $($sw.Elapsed.TotalSeconds) seconds"
