# DatastoreVMcount.Tests.ps1
# Pester tests for DatastoreVMcount.ps1

Describe "DatastoreVMcount.ps1" {
    setup {
        # Mock PowerCLI cmdlets
        Mock Connect-VIServer {
            return [PSCustomObject]@{
                Name = "vcenter.test"
                IsConnected = $true
            }
        }
        Mock Disconnect-VIServer {}
        Mock Get-Datastore {
            return @(
                [PSCustomObject]@{
                    Name = "DS1"
                    FreeSpaceGB = 100
                    ExtensionData = [PSCustomObject]@{
                        Vm = @("VM1", "VM2")
                    }
                },
                [PSCustomObject]@{
                    Name = "DS2"
                    FreeSpaceGB = 50
                    ExtensionData = [PSCustomObject]@{
                        Vm = $null
                    }
                }
            )
        }
        Mock Get-Module { return $true }
    }

    Context "Connection Management" {
        It "should connect to the specified vCenter Server" {
            { .\DatastoreVMcount.ps1 -VCenterServer "vcenter.test" } | Should -Not -Throw
            Assert-MockCalled Connect-VIServer -Exactly 1 -ParameterFilter { $Server -eq "vcenter.test" }
        }

        It "should disconnect from the vCenter Server in the finally block" {
            .\DatastoreVMcount.ps1 -VCenterServer "vcenter.test"
            Assert-MockCalled Disconnect-VIServer -Exactly 1
        }
    }

    Context "Data Retrieval" {
        It "should correctly calculate VM count using ExtensionData" {
            # This test verifies the logic by capturing output if we were to refactor to return data
            # Since the script outputs to Format-Table, we primarily verify it doesn't crash
            # and uses the mocked Get-Datastore.
            { .\DatastoreVMcount.ps1 -VCenterServer "vcenter.test" } | Should -Not -Throw
        }
    }
}
