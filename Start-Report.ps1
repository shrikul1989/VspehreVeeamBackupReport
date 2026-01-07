<#
.SYNOPSIS
    Main orchestration script for the vSphere & Veeam Consolidated Backup Report.
.DESCRIPTION
    This script connects to the infrastructure, gathers statistics, generates an HTML report, 
    and optionally emails it.
#>

param(
    [string]$vCenterServer,
    [string]$VeeamServer,
    [string]$SMTPServer,
    [string]$SMTPPort = "587",
    [string]$SMTPUser,
    [string]$SMTPPass,
    [string]$MailFrom,
    [string]$MailTo
)

# Set strict mode and error handling
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Define Paths
$ScriptRoot = $PSScriptRoot
$ScriptsDir = Join-Path $ScriptRoot "scripts"
$TemplateDir = Join-Path $ScriptRoot "templates"
$OutputDir = Join-Path $ScriptRoot "output"

# Import Helper Scripts
. (Join-Path $ScriptsDir "Connect-Infra.ps1")
. (Join-Path $ScriptsDir "Get-VirtStats.ps1")
. (Join-Path $ScriptsDir "Get-BaRStats.ps1")
. (Join-Path $ScriptsDir "Generate-HTML.ps1")
. (Join-Path $ScriptsDir "Send-ReportEmail.ps1")

Write-Host "Starting Consolidated Backup Report..." -ForegroundColor Cyan

# 1. Connect to Infrastructure
try {
    Connect-Infrastructure -vCenterServer $vCenterServer -VeeamServer $VeeamServer
}
catch {
    Write-Error "Failed to connect to infrastructure: $_"
    exit 1
}

# 2. Gather Data
Write-Host "Gathering vSphere Data..."
$vSphereData = Get-VirtStats

Write-Host "Gathering Veeam Data..."
$VeeamData = Get-BaRStats

# 3. Generate Report
Write-Host "Generating HTML Report..."
$ReportPath = Generate-HTMLReport -vSphereData $vSphereData -VeeamData $VeeamData -TemplateDir $TemplateDir -OutputDir $OutputDir

# 4. Send Email
if ($SMTPServer -and $MailTo) {
    Write-Host "Sending Email..."
    Send-ReportEmail -ReportPath $ReportPath -SMTPServer $SMTPServer -SMTPPort $SMTPPort -SMTPUser $SMTPUser -SMTPPass $SMTPPass -MailFrom $MailFrom -MailTo $MailTo
}

Write-Host "Process Completed. Report saved at: $ReportPath" -ForegroundColor Green
