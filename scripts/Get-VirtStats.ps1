function Get-VirtStats {
    Write-Host "Fetching vSphere VM data..."
    
    $VMs = Get-VM
    $Result = @()

    foreach ($VM in $VMs) {
        $Result += [PSCustomObject]@{
            Name = $VM.Name
            PowerState = $VM.PowerState
            Folder = ($VM | Get-Folder).Name
            Cluster = ($VM | Get-Cluster).Name
            UsedSpaceGB = [math]::Round($VM.UsedSpaceGB, 2)
            ProvisionedSpaceGB = [math]::Round($VM.ProvisionedSpaceGB, 2)
            Id = $VM.Id
        }
    }

    Write-Host "Found $($Result.Count) VMs."
    return $Result
}
