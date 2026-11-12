<#
.SYNOPSIS
    Automates disk initialization, partitioning, and formatting for secondary EBS volumes.
.DESCRIPTION
    Scans for all RAW/uninitialized disks attached to the Windows Server EC2 instance,
    initializes them with GPT, allocates full disk capacity to a single volume, assigns
    the next available drive letter, and formats as NTFS.
#>

[CmdletBinding()]
param (
    [string]$FileSystem = "NTFS"
)

Write-Host "Scanning for uninitialized EBS volumes..." -ForegroundColor Cyan

# Bring all offline disks online
Get-Disk | Where-Object IsOffline -eq $true | ForEach-Object {
    Write-Host "Bringing Disk $($_.Number) online..."
    Set-Disk -Number $_.Number -IsOffline $false
}

# Target all disks marked as RAW (Disk 1, Disk 2, Disk 3)
$rawDisks = Get-Disk | Where-Object PartitionStyle -eq 'RAW'

if (-not $rawDisks) {
    Write-Host "No uninitialized disks found." -ForegroundColor Green
    return
}

foreach ($disk in $rawDisks) {
    Write-Host "Initializing Disk $($disk.Number)..." -ForegroundColor Yellow
    Initialize-Disk -Number $disk.Number -PartitionStyle GPT

    Write-Host "Creating partition and formatting Disk $($disk.Number)..." -ForegroundColor Yellow
    $partition = New-Partition -DiskNumber $disk.Number -UseMaximumSize -AssignDriveLetter
    $driveLetter = $partition.DriveLetter

    $label = "Data-$driveLetter"
    Format-Volume -Partition $partition -FileSystem $FileSystem -NewFileSystemLabel $label -Confirm:$false

    Write-Host "Successfully mounted Disk $($disk.Number) as Drive ${driveLetter}: [$label]" -ForegroundColor Green
}

Get-Volume | Format-Table DriveLetter, FileSystemLabel, FileSystem, SizeRemaining, Size
