function Connect-Infrastructure {
    param (
        [string]$vCenterServer,
        [string]$VeeamServer
    )

    # Validate inputs
    if (-not $vCenterServer) { Throw "vCenterServer parameter is required." }
    if (-not $VeeamServer) { Throw "VeeamServer parameter is required." }

    # Connect to vCenter
    Write-Host "Connecting to vCenter: $vCenterServer"
    # Check if already connected
    if ($global:DefaultVIServer.Name -ne $vCenterServer) {
        try {
            Connect-VIServer -Server $vCenterServer -ErrorAction Stop | Out-Null
            Write-Host "Successfully connected to vCenter." -ForegroundColor Green
        }
        catch {
            Throw "Failed to connect to vCenter: $_"
        }
    } else {
        Write-Host "Already connected to vCenter."
    }

    # Connect to Veeam
    Write-Host "Connecting to Veeam Backup Server: $VeeamServer"
    try {
        # Veeam Snapin check
        if (-not (Get-PSSnapin -Name VeeamPSSnapIn -ErrorAction SilentlyContinue)) {
            Add-PSSnapin VeeamPSSnapIn -ErrorAction Stop
        }
        
        Connect-VBRServer -Server $VeeamServer -ErrorAction Stop | Out-Null
        Write-Host "Successfully connected to Veeam." -ForegroundColor Green
    }
    catch {
        Throw "Failed to connect to Veeam: $_"
    }
}
