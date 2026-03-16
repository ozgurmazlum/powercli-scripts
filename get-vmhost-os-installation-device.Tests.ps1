Describe "Get-VMHostOSInstallationDevice" {
    Context "When retrieving OS installation device" {
        Mock Connect-VIServer
        Mock Disconnect-VIServer

        It "Should use Get-View and avoid N+1 queries" {
            # Setup mocks for optimized behavior
            # Construct a fake View object (HostSystem)
            $mockView = [PSCustomObject]@{
                Name = "Host1"
                Config = [PSCustomObject]@{
                    DiagnosticPartition = [PSCustomObject]@{
                        Id = [PSCustomObject]@{
                            DiskName = "naa.123"
                        }
                    }
                    StorageDevice = [PSCustomObject]@{
                        ScsiLun = @(
                            [PSCustomObject]@{
                                CanonicalName = "naa.123"
                                DisplayName = "Disk1"
                                Model = "Model1"
                                DeviceName = "vmhba1:C0:T0:L0"
                                Vendor = "Vendor1"
                                DevicePath = "/vmfs/devices/disks/naa.123"
                            }
                        )
                    }
                }
            }

            Mock Get-View -MockWith { return $mockView }

            # Mock Get-VMHostDiagnosticPartition to ensure it's not called (though if not called, no mock needed,
            # but usually good to mock to prevent actual calls if logic fails)
            # Actually, if we Assert-MockCalled -Times 0, we don't strictly need to mock it unless it's called.
            # But creating a mock allows us to track calls.
            Mock Get-VMHostDiagnosticPartition

            # Run script
            $result = & ./get-vmhost-os-installation-device.ps1 -VCenterServer "vc.example.com"

            # Assert
            Assert-MockCalled Get-View -Times 1
            Assert-MockCalled Get-VMHostDiagnosticPartition -Times 0

            # Verify output
            $result | Should -Not -BeNullOrEmpty
            $result.VMHost | Should -Be "Host1"
            $result.DisplayName | Should -Be "Disk1"
            $result.CanonicalName | Should -Be "naa.123"
        }
    }
}
