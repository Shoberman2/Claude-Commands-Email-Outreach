<#
.SYNOPSIS
    Send an email via Outlook desktop using COM. Windows analog of send.sh.
.DESCRIPTION
    Drives the user's already-configured Outlook installation to compose and
    send a message. No SMTP credentials handled here — Outlook uses its
    existing account connections.
.PARAMETER To
    Recipient email address.
.PARAMETER Subject
    Email subject.
.PARAMETER BodyFile
    Path to a UTF-8 text file containing the email body.
.PARAMETER Draft
    Open as a draft window in Outlook instead of sending immediately.
#>
param(
    [Parameter(Mandatory=$true, Position=0)][string]$To,
    [Parameter(Mandatory=$true, Position=1)][string]$Subject,
    [Parameter(Mandatory=$true, Position=2)][string]$BodyFile,
    [switch]$Draft
)

$ErrorActionPreference = "Stop"

# Resolve the sender email from sender.txt sitting next to this script.
$senderFile = Join-Path $PSScriptRoot "sender.txt"
if (-not (Test-Path $senderFile)) {
    Write-Error "no sender configured. Write your sending email address to: $senderFile"
    exit 1
}
$sender = (Get-Content -Path $senderFile -TotalCount 1 -Encoding UTF8).Trim()
if (-not $sender) {
    Write-Error "$senderFile is empty"
    exit 1
}

if (-not (Test-Path $BodyFile)) {
    Write-Error "body file not found: $BodyFile"
    exit 1
}
$body = Get-Content -Path $BodyFile -Raw -Encoding UTF8

# Start Outlook (or attach to an already-running instance).
try {
    $outlook = New-Object -ComObject Outlook.Application
} catch {
    Write-Error "could not start Outlook. Install Outlook desktop and add your account."
    exit 1
}

# Find the matching Outlook account by SMTP address.
$account = $null
foreach ($acc in $outlook.Session.Accounts) {
    if ($acc.SmtpAddress -ieq $sender) {
        $account = $acc
        break
    }
}
if (-not $account) {
    $available = ($outlook.Session.Accounts | ForEach-Object { $_.SmtpAddress }) -join ", "
    Write-Error "sender '$sender' not found in Outlook accounts. Available: $available"
    exit 1
}

# Compose.
$olMailItem = 0
$mail = $outlook.CreateItem($olMailItem)
$mail.To = $To
$mail.Subject = $Subject
$mail.Body = $body

# Setting SendUsingAccount via direct assignment is a well-known Outlook COM
# gotcha — it silently no-ops on some Outlook versions. InvokeMember with the
# explicit SetProperty binding is the documented workaround.
[void]$mail.GetType().InvokeMember(
    "SendUsingAccount",
    [System.Reflection.BindingFlags]::SetProperty,
    $null,
    $mail,
    @([System.Object]$account)
)

if ($Draft) {
    $mail.Display()
} else {
    $mail.Send()
}
