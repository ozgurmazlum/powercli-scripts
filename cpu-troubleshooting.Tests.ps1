Describe "cpu-troubleshooting.ps1" {
    BeforeAll {
        # Mock PowerCLI cmdlets to avoid actual connections and errors
        Mock Get-Module { return $true }
        Mock Import-Module { }
        Mock Connect-VIServer { return "FakeConnection" }
        Mock Disconnect-VIServer { }
        Mock Get-VM {
            return [PSCustomObject]@{
                Name = "TestVM"
            }
        }
        Mock Get-VMHost {
            return [PSCustomObject]@{
                Name = "TestHost"
            }
        }
        Mock Write-Host { }
        Mock Write-Warning { }
        Mock Write-Error { }
    }

    Context "Edge Case: Empty Statistics" {
        It "displays a warning when Get-Stat returns no data for VM or Host usage" {
            # Mock Get-Stat to return an empty array for both VM and Host usage
            Mock Get-Stat { return @() }

            # Execute the script with dummy parameters
            # Using dot-sourcing to run the script in the current scope for mocks to work
            . ./cpu-troubleshooting.ps1 -VCenterServer "fake-vc" -VMName "TestVM"

            # Assert that Write-Warning was called with the specific message
            Assert-MockCalled Write-Warning -Times 1 -ParameterFilter {
                $Message -eq "Could not retrieve statistics. Ensure performance statistics are enabled and available."
            }
        }
    }

    Context "Normal Operation" {
        It "does not display a warning when Get-Stat returns valid statistics" {
            # Mock Get-Stat to return some valid-looking data
            Mock Get-Stat {
                return [PSCustomObject]@{
                    Value = 50
                    Instance = ""
                }
            }

            # Execute the script
            . ./cpu-troubleshooting.ps1 -VCenterServer "fake-vc" -VMName "TestVM"

            # Assert that Write-Warning was NOT called
            Assert-MockCalled Write-Warning -Times 0
        }
    }
}
