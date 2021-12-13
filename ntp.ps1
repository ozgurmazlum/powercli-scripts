Import-Module -name VMware.PowerCLI -ErrorAction Stop


Connect-VIServer -server "vcenter.yerelag.local"-username "administrator@vsphere.local" -password "Vmware01!!"

Get-VMHost | Get-VmHostService | Where-Object {$_.key-eq "ntpd"}

#Get-VMHost | Sort-Object Name | Select-Object Name, @{N=”Cluster”;E={$_ | Get-Cluster}}, @{N=”Datacenter”;E={$_ | Get-Datacenter}}, @{N=“NTPServiceRunning“;E={($_ | Get-VmHostService | Where-Object {$_.key-eq “ntpd“}).Running}}, @{N=“StartupPolicy“;E={($_ | Get-VmHostService | Where-Object {$_.key-eq “ntpd“}).Policy}}, @{N=“NTPServers“;E={$_ | Get-VMHostNtpServer}}, @{N="Date&Time";E={(get-view $_.ExtensionData.configManager.DateTimeSystem).QueryDateTime()}} | format-table -autosize



$currentNtp = "tr.pool.ntp.org"

$xVmHosts = Get-VMHost | Sort-Object Name

foreach ($xVmHost in $xVmHosts) {

    $xNtpServers = $xVmHost | Get-VMHostNtpServer

    if ($xNtpServers.Count -eq 0) {

        $xVmHost | Add-VMHostNtpServer -NtpServer $currentNtp

    } else {

        $xNtpServers | ForEach-Object {

            if ($_.NtpServer -eq $currentNtp) {

                $_.Remove() 

            }

        }

        $xVmHost | Add-VMHostNtpServer -NtpServer $currentNtp

    }


}



Disconnect-VIServer -Server * -Confirm:$false
