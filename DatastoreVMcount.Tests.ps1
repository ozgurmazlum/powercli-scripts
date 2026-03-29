Describe "DatastoreVMcount Logic" {
    Context "Performance Comparison" {
        It "Should measure the performance difference" {
            # Mock Data
            $mockDatastores = 1..100 | ForEach-Object {
                [PSCustomObject]@{
                    Name = "Datastore$_"
                    FreeSpaceGB = 100
                    ExtensionData = [PSCustomObject]@{
                        Vm = @(1..5) # 5 VMs per datastore
                    }
                }
            }

            # Old Logic (Simulated)
            $oldTime = Measure-Command {
                $resulth = @()
                foreach ($datastore in $mockDatastores) {
                    # Simulate Get-VM delay (overhead of cmdlet call + network latency)
                    # Even a tiny delay shows the issue with loop + API call
                    Start-Sleep -Milliseconds 10

                    # Simulate the Get-VM call which returns a collection of VMs
                    # In real scenario, Get-VM is called. Here we just take the count.
                    $vmCount = 5

                    # Inefficient array addition
                    $resulth += $datastore | Select-Object Name,@{N="VMCOUNT";E={$vmCount}},@{N="FREESPACE";E={$_.FreeSpaceGB}}
                }
            }

            # New Logic
            $newTime = Measure-Command {
                $resulth = foreach ($datastore in $mockDatastores) {
                    [PSCustomObject]@{
                        Name = $datastore.Name
                        VMCOUNT = $datastore.ExtensionData.Vm.Count
                        FREESPACE = $datastore.FreeSpaceGB
                    }
                }
            }

            Write-Host "Old Logic Time: $($oldTime.TotalMilliseconds) ms"
            Write-Host "New Logic Time: $($newTime.TotalMilliseconds) ms"

            $newTime.TotalMilliseconds | Should -BeLessThan $oldTime.TotalMilliseconds
        }
    }
}
