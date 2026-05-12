<#
.SYNOPSIS
    Install Claude Commands: Email Outreach on Windows. Windows analog of install.sh.
.DESCRIPTION
    Copies command files to $HOME\.claude\commands\ and sets up
    $HOME\email-outreach\ with send.ps1 and data templates. Idempotent —
    re-running keeps existing prospects, sent log, and sender config.
#>

$ErrorActionPreference = "Stop"

$repoDir = $PSScriptRoot
$cmdDir  = Join-Path $HOME ".claude\commands"
$dataDir = Join-Path $HOME "email-outreach"

Write-Host "Installing Claude Commands: Email Outreach"
Write-Host "  repo:  $repoDir"
Write-Host "  cmds:  $cmdDir"
Write-Host "  data:  $dataDir"
Write-Host ""

# Commands — always overwrite (these are code, not user data).
if (-not (Test-Path $cmdDir)) { New-Item -ItemType Directory -Path $cmdDir -Force | Out-Null }
foreach ($f in "find-emails.md", "email-all.md", "email-todo.md") {
    Copy-Item -Path (Join-Path $repoDir "commands\$f") -Destination (Join-Path $cmdDir $f) -Force
    Write-Host "  installed $cmdDir\$f"
}

# Data dir + send.ps1.
if (-not (Test-Path $dataDir)) { New-Item -ItemType Directory -Path $dataDir -Force | Out-Null }
Copy-Item -Path (Join-Path $repoDir "send.ps1") -Destination (Join-Path $dataDir "send.ps1") -Force
Write-Host "  installed $dataDir\send.ps1"

# Seed data files only if missing (preserve user data).
foreach ($f in "prospects.json", "sent.json") {
    $path = Join-Path $dataDir $f
    if (-not (Test-Path $path)) {
        [System.IO.File]::WriteAllText($path, "[]")
        Write-Host "  created  $path"
    } else {
        Write-Host "  kept     $path (already exists)"
    }
}

$todoPath = Join-Path $dataDir "TODO.md"
if (-not (Test-Path $todoPath)) {
    Copy-Item -Path (Join-Path $repoDir "templates\TODO.md") -Destination $todoPath -Force
    Write-Host "  created  $todoPath"
} else {
    Write-Host "  kept     $todoPath (already exists)"
}

# Sender configuration.
Write-Host ""
$senderPath = Join-Path $dataDir "sender.txt"
if ((Test-Path $senderPath) -and ((Get-Item $senderPath).Length -gt 0)) {
    $senderEmail = (Get-Content -Path $senderPath -TotalCount 1 -Encoding UTF8).Trim()
    Write-Host "Existing sender: $senderEmail"
    Write-Host "  (to change, edit $senderPath directly)"
} else {
    Write-Host "What email address should /email-all send from?"
    Write-Host "It must be an account already configured in Outlook desktop."
    $senderEmail = Read-Host "  sender email"
    if (-not $senderEmail) {
        Write-Error "empty sender, aborting"
        exit 1
    }
    [System.IO.File]::WriteAllText($senderPath, $senderEmail)
    Write-Host "  saved to $senderPath"
}

# Verify Outlook has the account.
Write-Host ""
Write-Host "Checking Outlook for $senderEmail..."
try {
    $outlook = New-Object -ComObject Outlook.Application
    $accounts = @($outlook.Session.Accounts | ForEach-Object { $_.SmtpAddress })
    if ($accounts -contains $senderEmail) {
        Write-Host "  ok: $senderEmail is configured in Outlook"
    } else {
        Write-Host "  warning: $senderEmail was NOT found in Outlook."
        Write-Host "  Outlook accounts: $($accounts -join ', ')"
        Write-Host "  Add the account in Outlook, or edit $senderPath."
    }
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($outlook) | Out-Null
} catch {
    Write-Host "  warning: could not query Outlook. Make sure Outlook desktop is installed."
}

Write-Host ""
Write-Host "Done. Start Claude Code and try:"
Write-Host "  /find-emails  indie hackers building developer tools"
Write-Host "  /email-all"
Write-Host "  /email-todo"
