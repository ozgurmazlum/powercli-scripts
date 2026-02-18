<#
.SYNOPSIS
    Analyzes CPU usage and CPU Ready time for a VM and its host.

.DESCRIPTION
    Connects to vCenter, retrieves real-time CPU statistics for the specified VM and its host,
    and displays a color-coded report.

.PARAMETER VCenterServer
    The vCenter server address.

.PARAMETER VMName
    The name of the virtual machine to analyze.
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
} catch {
    Write-Error "VM '$VMName' not found."
    Disconnect-VIServer -Server $connection -Confirm:$false -Force
    exit 1
}

$vmHost = $vm | Get-VMHost

Write-Host "Analyzing CPU statistics for VM: $($vm.Name) on Host: $($vmHost.Name)..." -ForegroundColor Cyan

# Get Stats
# Note: Realtime interval usually requires statistics level 1.
$vmStats = $vm | Get-Stat -Stat cpu.usage.average -Realtime -MaxSamples 10 -ErrorAction SilentlyContinue | Where-Object { $_.Instance -eq "" } | Measure-Object Value -Average -Maximum
$hostStats = $vmHost | Get-Stat -Stat cpu.usage.average -Realtime -MaxSamples 10 -ErrorAction SilentlyContinue | Where-Object { $_.Instance -eq "" } | Measure-Object Value -Average -Maximum

if (-not $vmStats.Count -or -not $hostStats.Count) {
    Write-Warning "Could not retrieve statistics. Ensure performance statistics are enabled and available."
}

$HostCpuAverage = if ($hostStats.Average) { [math]::Round($hostStats.Average) } else { 0 }
$HostCpuMax = if ($hostStats.Maximum) { [math]::Round($hostStats.Maximum) } else { 0 }

$VmCpuAverage = if ($vmStats.Average) { [math]::Round($vmStats.Average) } else { 0 }
$VmCpuMax = if ($vmStats.Maximum) { [math]::Round($vmStats.Maximum) } else { 0 }


Write-Host
Write-Host "Guest CPU Information" -ForegroundColor Cyan
Write-Host

if($VmCpuAverage -gt 75 -or $VmCpuMax -gt 90){
    Write-Host "---------- VM CPU High !!! -----------" -ForegroundColor White -BackgroundColor DarkRed
    Write-Host "VM Name : $($vm.Name)"
    Write-Host "VM Cpu Average % : $VmCpuAverage"
    Write-Host "VM Cpu Max % :  $VmCpuMax"
    Write-Host "--------------------------------------" -ForegroundColor White -BackgroundColor DarkRed
} else {
    Write-Host "---------- VM CPU Normal -----------" -ForegroundColor White -BackgroundColor DarkGreen
    Write-Host "VM Name : $($vm.Name)"
    Write-Host "VM Cpu Average % : $VmCpuAverage"
    Write-Host "VM Cpu Max % :  $VmCpuMax"
    Write-Host "------------------------------------" -ForegroundColor White -BackgroundColor DarkGreen
}

Write-Host
Write-Host "Host CPU Information" -ForegroundColor Cyan
Write-Host

if($HostCpuAverage -gt 75 -or $HostCpuMax -gt 90){
    Write-Host "---------- HOST CPU High !!! -----------" -ForegroundColor White -BackgroundColor DarkRed
    Write-Host "Host Name : $($vmHost.Name)"
    Write-Host "Host Cpu Average % :  $HostCpuAverage"
    Write-Host "Host Cpu Max % :  $HostCpuMax"
    Write-Host "----------------------------------------" -ForegroundColor White -BackgroundColor DarkRed
} else {
    Write-Host "---------- HOST CPU Normal -----------" -ForegroundColor White -BackgroundColor Green
    Write-Host "Host Name : $($vmHost.Name)"
    Write-Host "Host Cpu Average % : $HostCpuAverage"
    Write-Host "Host Cpu Max % :  $HostCpuMax"
    Write-Host "--------------------------------------" -ForegroundColor White -BackgroundColor Green
}

# CPU Ready Check (Moved outside the else block for better visibility)
Write-Host
Write-Host "Checking CPU Ready..." -ForegroundColor Cyan

$cpuReady = $vm | Get-Stat -Stat cpu.ready.summation -Realtime -MaxSamples 10 -ErrorAction SilentlyContinue | Where-Object { $_.Instance -eq "" } | Measure-Object Value -Average -Maximum
$cpuReadyTimeAverage = if ($cpuReady.Average) { [math]::Round($cpuReady.Average) } else { 0 }

if($cpuReadyTimeAverage -gt 2000){
    Write-Host "---------- CPU Ready Time High -----------" -ForegroundColor White -BackgroundColor Red
    Write-Host "VM Name : $($vm.Name)"
    Write-Host "CPU Ready Time : $cpuReadyTimeAverage ms"
    Write-Host "------------------------------------------" -ForegroundColor White -BackgroundColor Red
} else {
    Write-Host "---------- CPU Ready Time Normal -----------" -ForegroundColor White -BackgroundColor Green
    Write-Host "VM Name : $($vm.Name)"
    Write-Host "CPU Ready Time : $cpuReadyTimeAverage ms"
    Write-Host "--------------------------------------------" -ForegroundColor White -BackgroundColor Green
}

Write-Host

# Disconnect
if ($connection) {
    Disconnect-VIServer -Server $connection -Confirm:$false -Force
}
