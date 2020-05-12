Get-VM | Get-View | Where-Object {$_.Guest.GuestId -and $_.Guest.GuestId -ne $_.Config.GuestId} | Select-Object -Property Name,@{N="GuestId";E={$_.Guest.GuestId}}, @{N="Installed Guest OS";E={$_.Guest.GuestFullName}},@{N="Configured GuestId";E={$_.Config.GuestId}}, @{N="Configured Guest OS";E={$_.Config.GuestFullName}} | Export-Csv -Path .\correct-ostype.csv -NoTypeInformation

Invoke-Item -Path .\correct-ostype.csv
