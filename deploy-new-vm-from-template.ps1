PowerShell
Import-Module -Name VMware.PowerCLI

Connect-VIServer -Server vcenteripaddress

$localUser = $env:USERNAME

## change write-server-name with new serve name
$VmName = "testserver1"

#Template name
$Template = Get-Template -Name "Template2020"

##Select Cluster
$Cluster = Get-Cluster -Name "clustername" | Get-VMHost | Get-Random

#Select Folder exp: Eger bir klasor yapisi kullaniyorsaniz buradaki klasor id bilgisini ihtiyaciniz var.
#Folder id sini referans almak istedginiz vm icin bu komut yazarsaniz size id numarasini dondurecektir. Get-VM vmname | select FolderId

$FolderId = Get-Folder -Id "Folder-group-v48880"

## Selects the drive with the highest free space

## Burada datastore secimi yapacagiz ozellikle istediginiz bir datastore prefix varsa * karaktari ile kullanabilirsiniz. Ornek olarakWIN adi ile baslayan datastore yazarsaniz  tum datastoreleri listeler bunlarin icindeki free space en yuksek olani secer.
$Datastore = Get-Datastore -Name datastorename* | sort FreeSpaceGB -Descending | select -First 1 -ExpandProperty Name

# New Virtual machine details
New-VM -Name $VmName -Template $Template -VMHost $Cluster -Location $FolderId -Datastore $Datastore -DiskStorageFormat Thin

Start-VM -VM $VmName

Open-VMConsoleWindow -VM $VmName

Disconnect-VIServer -Server * -Force
1
2
3
4
5
6
7
8
9
10
11
12
13
14
15
16
17
18
19
20
21
22
23
24
25
26
27
28
29
30
31
32
33
Import-Module -Name VMware.PowerCLI
 
Connect-VIServer -Server vcenteripaddress
 
$localUser = $env:USERNAME
 
## change write-server-name with new serve name
$VmName = "testserver1"
 
#Template name
$Template = Get-Template -Name "Template2020"
 
##Select Cluster
$Cluster = Get-Cluster -Name "clustername" | Get-VMHost | Get-Random
 
#Select Folder exp: Eger bir klasor yapisi kullaniyorsaniz buradaki klasor id bilgisini ihtiyaciniz var.
#Folder id sini referans almak istedginiz vm icin bu komut yazarsaniz size id numarasini dondurecektir. Get-VM vmname | select FolderId
 
$FolderId = Get-Folder -Id "Folder-group-v48880"
 
## Selects the drive with the highest free space
 
## Burada datastore secimi yapacagiz ozellikle istediginiz bir datastore prefix varsa * karaktari ile kullanabilirsiniz. Ornek olarakWIN adi ile baslayan datastore yazarsaniz  tum datastoreleri listeler bunlarin icindeki free space en yuksek olani secer.
$Datastore = Get-Datastore -Name datastorename* | sort FreeSpaceGB -Descending | select -First 1 -ExpandProperty Name
 
# New Virtual machine details
New-VM -Name $VmName -Template $Template -VMHost $Cluster -Location $FolderId -Datastore $Datastore -DiskStorageFormat Thin
 
Start-VM -VM $VmName
 
Open-VMConsoleWindow -VM $VmName
 
Disconnect-VIServer -Server * -Force
