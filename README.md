# AWS EC2 Windows Server Storage Deployment with Amazon EBS

An enterprise cloud infrastructure lab deploying a Windows Server instance on Amazon EC2 and provisioning multi-tier Elastic Block Store (EBS) block storage, simulating hybrid-cloud disk architecture and administrative storage workflows.

---

## Architecture Overview

```
                      +---------------------------------------+
                      |               AWS VPC                 |
                      |                                       |
                      |   +-------------------------------+   |
                      |   |   EC2 Windows Server 2025     |   |
                      |   |   (t3.micro / us-east-2)      |   |
                      |   +---------------+---------------+   |
                      |                   |                   |
                      +-------------------|-------------------+
                                          |
                +-------------------------+-------------------------+
                |                         |                         |
        +-------v-------+         +-------v-------+         +-------v-------+
        | Root Volume   |         | EBS Volume 1  |         | EBS Volume 2  |
        | 30 GiB (gp3)  |         | 2 GiB (gp3)   |         | 2 GiB (gp3)   |
        | Mount: C:\    |         | Mount: D:\    |         | Mount: E:\    |
        +---------------+         +---------------+         +---------------+
                                          |
                                  +-------v-------+
                                  | EBS Volume 3  |
                                  | 2 GiB (gp3)   |
                                  | Mount: F:\    |
                                  +---------------+
```

---

## Technical Specifications

| Parameter | Configuration |
|---|---|
| **Cloud Provider** | Amazon Web Services (AWS) |
| **Compute Instance** | Amazon EC2 (`t3.micro`) |
| **Operating System** | Microsoft Windows Server 2025 Base |
| **Region / AZ** | `us-east-2b` |
| **Network Security** | Inbound TCP `3389` (RDP) scoped to Admin IP |
| **Root Volume** | `30 GiB` gp3 (Boot/OS) |
| **Attached Storage** | 3x `2 GiB` EBS Block Volumes |
| **Partition Table** | GPT (GUID Partition Table) |
| **Filesystem** | NTFS (4KB allocation unit) |

---

## Volume Mapping & Mount Configuration

| Physical Disk | EBS Volume Size | Partition Style | Drive Letter | Volume Label | Status |
|---|---|---|---|---|---|
| **Disk 0** | 30 GiB | GPT | `C:` | `Windows` | System, Boot, Page File |
| **Disk 1** | 2 GiB | GPT | `D:` | `Mukwaya Lwere` | Healthy (Basic Data) |
| **Disk 2** | 2 GiB | GPT | `E:` | `Lwere2` | Healthy (Basic Data) |
| **Disk 3** | 2 GiB | GPT | `F:` | `Lwere3` | Healthy (Basic Data) |

---

## Implementation Steps

### 1. Compute & Block Storage Provisioning
- Deployed EC2 Windows Server 2025 instance in `us-east-2b` with an RSA-backed key pair.
- Attached a 30 GiB gp3 root EBS volume and provisioned three secondary 2 GiB block storage volumes.
- Scoped security group ingress rules to port `3389` for secure remote administration.

### 2. Administrative Access via RDP
- Retrieved and decrypted local `Administrator` credentials using AWS EC2 console key-pair decryption.
- Established remote desktop session via Windows App / Remote Desktop Client to the public IPv4 endpoint.

### 3. Disk Initialization & Partitioning
- Initialized unallocated raw block volumes via **Disk Management** (`diskmgmt.msc`) using GUID Partition Table (GPT).
- Provisioned simple volumes formatted with NTFS, assigning persistent drive mount points (`D:`, `E:`, `F:`) and distinct naming conventions.

---

## Automated Storage Provisioning (PowerShell)

To automate the initialization and formatting demonstrated via GUI, execute the script located in `scripts/initialize-disks.ps1`:

```powershell
Get-Disk | Where-Object PartitionStyle -Eq 'RAW' | ForEach-Object {
    Initialize-Disk -Number $_.Number -PartitionStyle GPT
    $partition = New-Partition -DiskNumber $_.Number -UseMaximumSize -AssignDriveLetter
    Format-Volume -Partition $partition -FileSystem NTFS -NewFileSystemLabel "EBS-Data-$($_.Number)" -Confirm:$false
}
```

---

## Security & Cost Governance

- **Credential Rotation**: Recommended rotating default Windows Administrator passwords immediately following first boot.
- **Access Management**: Avoid opening port `3389` to `0.0.0.0/0`; enforce source IP restrictions.
- **Resource Decommissioning**: Instances transitioned to `Stopped` state halt vCPU/RAM billing; extra non-root EBS block volumes can be detached and deleted to prevent residual storage charges.
