function Generate-HTMLReport {
    param(
        $vSphereData,
        $VeeamData,
        $TemplateDir,
        $OutputDir
    )

    Write-Host "Process Data Correlation..."

    # 1. Correlate Data
    $TotalVMs = $vSphereData.Count
    $ProtectedVMsList = $VeeamData.ProtectedVMs
    $ProtectedCount = $ProtectedVMsList.Count
    
    # Identify Unprotected VMs
    # Compare vSphere VM Names with Veeam Protected VM Names
    $ProtectedNames = $ProtectedVMsList.VMName
    $UnprotectedVMs = $vSphereData | Where-Object { $ProtectedNames -notcontains $_.Name }
    $UnprotectedCount = $UnprotectedVMs.Count

    # Calculate Success Rate (Based on Job LastResult)
    $Jobs = $VeeamData.Jobs
    $SuccessJobs = $Jobs | Where-Object { $_.LastResult -eq 'Success' }
    $SuccessRate = if ($Jobs.Count -gt 0) { [math]::Round(($SuccessJobs.Count / $Jobs.Count) * 100, 1) } else { 0 }

    # Repository Data for Chart
    $RepoLabels = $VeeamData.Repositories.Name
    $RepoFreeSpace = $VeeamData.Repositories.FreeSpaceGB

    # 2. Read Template
    $TemplatePath = Join-Path $TemplateDir "report_template.html"
    if (-not (Test-Path $TemplatePath)) { Throw "Template not found at $TemplatePath" }
    $HtmlContent = Get-Content $TemplatePath -Raw

    # 3. Generate HTML Fragments
    
    # Unprotected Rows
    $UnprotectedRows = ""
    foreach ($vm in $UnprotectedVMs) {
        $UnprotectedRows += "<tr>
            <td>$($vm.Name)</td>
            <td>$($vm.Folder)</td>
            <td>$($vm.Cluster)</td>
            <td><span class='status-badge $(if($vm.PowerState -eq 'PoweredOn'){'status-success'}else{'status-warning'})'>$($vm.PowerState)</span></td>
        </tr>"
    }
    if (-not $UnprotectedRows) { $UnprotectedRows = "<tr><td colspan='4'>All VMs are Protected!</td></tr>" }

    # Job Rows
    $JobRows = ""
    foreach ($job in $Jobs) {
        $StatusClass = switch ($job.LastResult) {
            "Success" { "status-success" }
            "Failed" { "status-error" }
            default { "status-warning" }
        }
        $JobRows += "<tr>
            <td>$($job.JobName)</td>
            <td><span class='status-badge $StatusClass'>$($job.LastResult)</span></td>
            <td>$($job.LastRunTime)</td>
        </tr>"
    }

    # 4. Inject Data into Template
    $HtmlContent = $HtmlContent.Replace("<!-- TIMESTAMP_PLACEHOLDER -->", (Get-Date).ToString("yyyy-MM-dd HH:mm"))
    $HtmlContent = $HtmlContent.Replace("<!-- TOTAL_VMS_PLACEHOLDER -->", $TotalVMs)
    $HtmlContent = $HtmlContent.Replace("<!-- PROTECTED_VMS_PLACEHOLDER -->", $ProtectedCount)
    $HtmlContent = $HtmlContent.Replace("<!-- UNPROTECTED_VMS_PLACEHOLDER -->", $UnprotectedCount)
    $HtmlContent = $HtmlContent.Replace("<!-- SUCCESS_RATE_PLACEHOLDER -->", $SuccessRate)
    
    $HtmlContent = $HtmlContent.Replace("<!-- UNPROTECTED_ROWS_PLACEHOLDER -->", $UnprotectedRows)
    $HtmlContent = $HtmlContent.Replace("<!-- JOB_ROWS_PLACEHOLDER -->", $JobRows)

    # JS Data
    $HtmlContent = $HtmlContent.Replace("<!-- JS_PROTECTED_COUNT -->", $ProtectedCount)
    $HtmlContent = $HtmlContent.Replace("<!-- JS_UNPROTECTED_COUNT -->", $UnprotectedCount)
    $HtmlContent = $HtmlContent.Replace("<!-- JS_REPO_LABELS -->", ($RepoLabels | ConvertTo-Json -Compress))
    $HtmlContent = $HtmlContent.Replace("<!-- JS_REPO_DATA -->", ($RepoFreeSpace | ConvertTo-Json -Compress))

    # 5. Save Report
    if (-not (Test-Path $OutputDir)) { New-Item -ItemType Directory -Path $OutputDir | Out-Null }
    $ReportFilename = "BackupReport_$(Get-Date -Format 'yyyyMMdd').html"
    $ReportPath = Join-Path $OutputDir $ReportFilename
    $HtmlContent | Set-Content -Path $ReportPath

    return $ReportPath
}
