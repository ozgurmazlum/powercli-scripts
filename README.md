# VMware PowerCLI Scripts

A collection of PowerShell scripts for VMware administration using PowerCLI.

## Scripts

### 1. `esxcli-kill.ps1`
Kills a VM process on an ESXi host using ESXCLI (tunneled through vCenter).

**Usage:**
```powershell
.\esxcli-kill.ps1 -VCenterServer "vcenter.example.com" -VMName "MyVM"
```

### 2. `cpu-troubleshooting.ps1`
Analyzes CPU usage and CPU Ready time for a specific VM and its host, providing a color-coded report.

**Usage:**
```powershell
.\cpu-troubleshooting.ps1 -VCenterServer "vcenter.example.com" -VMName "MyVM"
```

### 3. `get-inactive-poweredstate-vmlist.ps1`
Retrieves a list of PoweredOn VMs that have network adapters configured with 'StartConnected' as false.

**Usage:**
```powershell
.\get-inactive-poweredstate-vmlist.ps1 -VCenterServer "vcenter.example.com"
# Optional: Filter by name
.\get-inactive-poweredstate-vmlist.ps1 -VCenterServer "vcenter.example.com" -VMNamePattern "Prod-*"
```

### 4. `get-multiple-nic-vm-list.ps1`
Lists VMs that have more than one network adapter.

**Usage:**
```powershell
.\get-multiple-nic-vm-list.ps1 -VCenterServer "vcenter.example.com"
```

### 5. `get-vmhost-os-installation-device.ps1`
Retrieves the OS installation storage device details for ESXi hosts.

**Usage:**
```powershell
.\get-vmhost-os-installation-device.ps1 -VCenterServer "vcenter.example.com"
```

### 6. `find-vlan-id.ps1`
Searches for PortGroups by VLAN ID. (Note: Check script content for specific usage).

### 7. `vflash-read-cache.ps1`
Lists hosts and VMs with vFlash Read Cache configured.

---

## Requirements
* VMware PowerCLI module (`Install-Module -Name VMware.PowerCLI`)
* PowerShell 5.1 or later (Core 7+ recommended)
