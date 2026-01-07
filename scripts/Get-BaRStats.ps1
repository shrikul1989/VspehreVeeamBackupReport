function Get-BaRStats {
    Write-Host "Fetching Veeam Backup data..."

    # 1. Get All Backup Jobs
    $Jobs = Get-VBRJob
    $JobStats = @()
    foreach ($Job in $Jobs) {
        $LastSession = $Job | Get-VBRJobSession | Sort-Object CreationTime -Descending | Select-Object -First 1
        $JobStats += [PSCustomObject]@{
            JobName = $Job.Name
            JobType = $Job.JobType
            LastResult = if ($LastSession) { $LastSession.Result } else { "Never Run" }
            LastRunTime = if ($LastSession) { $LastSession.CreationTime } else { $null }
        }
    }

    # 2. Get Protected VMs (Restore Points)
    # We look at the latest restore point for each VM
    $RestorePoints = Get-VBRRestorePoint | Sort-Object CreationTime -Descending
    # Group by VM Name to get the latest point
    $ProtectedVMs = $RestorePoints | Group-Object VMName | ForEach-Object {
        $LatestPoint = $_.Group | Select-Object -First 1
        [PSCustomObject]@{
            VMName = $_.Name
            LatestRestorePoint = $LatestPoint.CreationTime
            BackupJob = $LatestPoint.JobName
            Repository = (Get-VBRBackupRepository -Id $LatestPoint.RepositoryId).Name
        }
    }

    # 3. Repository Stats
    $Repositories = Get-VBRBackupRepository
    $RepoStats = @()
    foreach ($Repo in $Repositories) {
        $Container = $Repo.GetContainer()
        $RepoStats += [PSCustomObject]@{
            Name = $Repo.Name
            Type = $Repo.Type
            Path = $Repo.Path
            FreeSpaceGB = [math]::Round($Container.CachedFreeSpace / 1GB, 2)
            TotalSpaceGB = [math]::Round($Container.CachedTotalSpace / 1GB, 2)
        }
    }

    return [PSCustomObject]@{
        Jobs = $JobStats
        ProtectedVMs = $ProtectedVMs
        Repositories = $RepoStats
    }
}
