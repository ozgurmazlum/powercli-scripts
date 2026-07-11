Describe "vflash-read-cache.ps1" {
    BeforeAll {
        # Mocking PowerCLI cmdlets
        Mock Connect-VIServer { }
        Mock Disconnect-VIServer { }
        Mock Import-Module { }
        Mock Get-Module { return $null }
        Mock Write-Host { }
    }

    It "should correctly report hosts and VMs with vFlash cache" {
        # Mock host
        $mockHost = [PSCustomObject]@{
            Name = "ESXi-01"
        }

        # Mock host view
        $mockHostView = [PSCustomObject]@{
            config = [PSCustomObject]@{
                VFlashConfigInfo = [PSCustomObject]@{
                    VFlashResourceConfigInfo = [PSCustomObject]@{
                        Capacity = 10GB
                    }
                }
            }
        }

        Mock Get-VMHost { return $mockHost }
        Mock Get-View { return $mockHostView }

        # Mock VM
        $mockVM = [PSCustomObject]@{
            Name = "VM-01"
            VMHost = [PSCustomObject]@{ Name = "ESXi-01" }
        }

        # Mock Disk
        $mockDisk = [PSCustomObject]@{
            Name = "Hard disk 1"
            ExtensionData = [PSCustomObject]@{
                vFlashCacheConfigInfo = [PSCustomObject]@{
                    ReservationInMB = 1024
                }
            }
        }

        Mock Get-VM { return $mockVM }
        Mock Get-HardDisk { return $mockDisk }

        $output = & $PSScriptRoot/vflash-read-cache.ps1 -VCenterServer "vc.example.com"

        $output | Should -Contain "ESXi-01 Cache Size : 10 GB"
        $output | Should -Contain "Hard disk 1 Cache Size : 1024"
    }

    It "should correctly handle hosts and VMs without vFlash cache" {
        # Mock host
        $mockHost = [PSCustomObject]@{
            Name = "ESXi-02"
        }

        # Mock host view without vFlash
        $mockHostView = [PSCustomObject]@{
            config = [PSCustomObject]@{
                VFlashConfigInfo = [PSCustomObject]@{
                    VFlashResourceConfigInfo = [PSCustomObject]@{
                        Capacity = 0
                    }
                }
            }
        }

        Mock Get-VMHost { return $mockHost }
        Mock Get-View { return $mockHostView }

        # Mock VM
        $mockVM = [PSCustomObject]@{
            Name = "VM-02"
            VMHost = [PSCustomObject]@{ Name = "ESXi-02" }
        }

        # Mock Disk without vFlash
        $mockDisk = [PSCustomObject]@{
            Name = "Hard disk 1"
            ExtensionData = [PSCustomObject]@{
                vFlashCacheConfigInfo = [PSCustomObject]@{
                    ReservationInMB = 0
                }
            }
        }

        Mock Get-VM { return $mockVM }
        Mock Get-HardDisk { return $mockDisk }

        $output = & $PSScriptRoot/vflash-read-cache.ps1 -VCenterServer "vc.example.com"

        $output | Should -Not -Contain "ESXi-02 Cache Size"
        $output | Should -Not -Contain "Hard disk 1 Cache Size"
    }
}
