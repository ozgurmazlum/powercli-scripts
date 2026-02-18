
<#
.SYNOPSIS
    Pester tests for get-multiple-nic-vm-list.ps1
#>

$scriptPath = "$PSScriptRoot/get-multiple-nic-vm-list.ps1"

Describe "get-multiple-nic-vm-list.ps1" {
    Context "When finding VMs with multiple NICs" {
        # Mock PowerCLI cmdlets
        Mock Connect-VIServer { return [PSCustomObject]@{ Name = "vCenter" } }
        Mock Disconnect-VIServer { }
        Mock Get-Module { return $true }
        Mock Import-Module { }

        It "Should correctly identify VMs with more than 1 NIC using Get-View" {
            # Mock Data
            # VM1 has 1 NIC
            $vm1 = [PSCustomObject]@{
                Name = "VM1"
                Config = [PSCustomObject]@{
                    Hardware = [PSCustomObject]@{
                        Device = @(
                            [PSCustomObject]@{
                                Key = 4000
                                PSTypeNames = @("VMware.Vim.VirtualEthernetCard")
                            }
                        )
                    }
                }
            }

            # VM2 has 2 NICs
            $vm2 = [PSCustomObject]@{
                Name = "VM2"
                Config = [PSCustomObject]@{
                    Hardware = [PSCustomObject]@{
                        Device = @(
                            [PSCustomObject]@{
                                Key = 4000
                                PSTypeNames = @("VMware.Vim.VirtualEthernetCard")
                            },
                            [PSCustomObject]@{
                                Key = 4001
                                PSTypeNames = @("VMware.Vim.VirtualEthernetCard")
                            }
                        )
                    }
                }
            }

            # VM3 has 0 NICs (just a disk)
            $vm3 = [PSCustomObject]@{
                Name = "VM3"
                Config = [PSCustomObject]@{
                    Hardware = [PSCustomObject]@{
                        Device = @(
                            [PSCustomObject]@{
                                Key = 1000
                                PSTypeNames = @("VMware.Vim.VirtualDisk")
                            }
                        )
                    }
                }
            }

            # Mock Get-View to return our mock VMs
            Mock Get-View { return @($vm1, $vm2, $vm3) } -ParameterFilter { $ViewType -eq "VirtualMachine" }

            # Run the script
            # We use & to invoke the script in the current scope context so mocks apply
            $result = & $scriptPath -VCenterServer "dummy-vcenter"

            # Assertions
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 1
            $result[0].VMName | Should -Be "VM2"
            $result[0].NicCount | Should -Be 2
        }

        It "Should handle VMs with no NICs gracefully" {
             # VM3 has 0 NICs
            $vm3 = [PSCustomObject]@{
                Name = "VM3"
                Config = [PSCustomObject]@{
                    Hardware = [PSCustomObject]@{
                        Device = @(
                            [PSCustomObject]@{
                                Key = 1000
                                PSTypeNames = @("VMware.Vim.VirtualDisk")
                            }
                        )
                    }
                }
            }

            Mock Get-View { return @($vm3) } -ParameterFilter { $ViewType -eq "VirtualMachine" }

            $result = & $scriptPath -VCenterServer "dummy-vcenter"
            $result | Should -BeNullOrEmpty
        }
    }
}
