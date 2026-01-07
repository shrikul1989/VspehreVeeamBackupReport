function Send-ReportEmail {
    param(
        [string]$ReportPath,
        [string]$SMTPServer,
        [string]$SMTPPort,
        [string]$SMTPUser,
        [string]$SMTPPass,
        [string]$MailFrom,
        [string]$MailTo
    )

    Write-Host "Sending email to $MailTo..."

    $Subject = "Weekly Infrastructure Backup Report - $(Get-Date -Format 'yyyy-MM-dd')"
    $Body = @"
<html>
<body style="font-family: sans-serif;">
    <h2 style="color: #29313b;">Backup Report Ready</h2>
    <p>The weekly backup report has been generated.</p>
    <p><strong>Date:</strong> $(Get-Date)</p>
    <p>Please find the detailed HTML report attached.</p>
    <hr>
    <small>Automated Message</small>
</body>
</html>
"@

    $Parameters = @{
        To = $MailTo
        From = $MailFrom
        Subject = $Subject
        Body = $Body
        BodyAsHtml = $True
        SmtpServer = $SMTPServer
        Port = $SMTPPort
        UseSsl = $True
        Attachments = $ReportPath
    }

    if ($SMTPUser -and $SMTPPass) {
        $SecurePass = $SMTPPass | ConvertTo-SecureString -AsPlainText -Force
        $Cred = New-Object System.Management.Automation.PSCredential($SMTPUser, $SecurePass)
        $Parameters.Credential = $Cred
    }

    try {
        Send-MailMessage @Parameters
        Write-Host "Email sent successfully!" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to send email: $_"
    }
}
