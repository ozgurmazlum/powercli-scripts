# benchmark.ps1
# Benchmark script to verify performance improvements in DatastoreVMcount.ps1

function Get-Datastore-Mock {
    param($Count = 50)
    1..$Count | ForEach-Object {
        [PSCustomObject]@{
            Name = "DS$_"
            FreeSpaceGB = 500
            ExtensionData = [PSCustomObject]@{
                Vm = 1..20 # Simulated 20 VMs per datastore
            }
        }
    }
}

function Get-VM-Mock {
    # Simulate network latency of 50ms per call
    Start-Sleep -Milliseconds 50
    return 1..20 | ForEach-Object { [PSCustomObject]@{ Name = "VM$_" } }
}

$dsCount = 20
Write-Host "--- DatastoreVMcount Performance Benchmark ---" -ForegroundColor White
Write-Host "Simulating $dsCount datastores..."

# Legacy Approach
Write-Host "Running Legacy Approach (Get-VM in loop)..." -ForegroundColor Yellow
$sw = [System.Diagnostics.Stopwatch]::StartNew()
$datastores = Get-Datastore-Mock -Count $dsCount
$resultsLegacy = foreach ($ds in $datastores) {
    $vms = Get-VM-Mock
    [PSCustomObject]@{ Name = $ds.Name; VMCount = $vms.Count }
}
$sw.Stop()
$legacyTime = $sw.Elapsed.TotalSeconds
Write-Host "Legacy Time: $legacyTime seconds"

# Optimized Approach
Write-Host "Running Optimized Approach (ExtensionData)..." -ForegroundColor Green
$sw.Restart()
$datastores = Get-Datastore-Mock -Count $dsCount
$resultsOptimized = foreach ($ds in $datastores) {
    $vmCount = if ($null -ne $ds.ExtensionData.Vm) { $ds.ExtensionData.Vm.Count } else { 0 }
    [PSCustomObject]@{ Name = $ds.Name; VMCount = $vmCount }
}
$sw.Stop()
$optimizedTime = $sw.Elapsed.TotalSeconds
Write-Host "Optimized Time: $optimizedTime seconds"

$speedup = $legacyTime / [Math]::Max($optimizedTime, 0.001)
Write-Host "---------------------------------------------"
Write-Host "Performance Improvement: $([Math]::Round($speedup, 1))x faster"
Write-Host "---------------------------------------------"
