# Cara 1 (tanpa buka web): tampal dalam PowerShell
#   irm https://raw.githubusercontent.com/Hanricus/ps-profile/main/install.ps1 | iex
# Cara 2: git clone repo, lepas tu run .\install.ps1
# Run baris yang sama lagi sekali untuk UPDATE. Route, setting dan local.ps1 kau tak disentuh.

function Install-PSRoutes {
    $ErrorActionPreference = "Stop"
    $Owner  = "Hanricus"
    $Repo   = "ps-profile"
    $Branch = "main"
    $ProfileFile = "Microsoft.PowerShell_profile.ps1"

    $docs = [Environment]::GetFolderPath("MyDocuments")
    $targets = @(Join-Path $docs "WindowsPowerShell\$ProfileFile")
    if (Get-Command pwsh -ErrorAction SilentlyContinue) {
        $targets += Join-Path $docs "PowerShell\$ProfileFile"
    }

    # Data folder (routes, config, local.ps1) is separate from the app folder, so updates never touch it.
    $dataDir = Join-Path $env:USERPROFILE "PSRoutes"
    $appDir  = Join-Path $dataDir "app"
    $fromClone = $PSScriptRoot -and (Test-Path (Join-Path $PSScriptRoot $ProfileFile))
    $isUpdate  = (-not $fromClone) -and (Test-Path (Join-Path $appDir $ProfileFile))
    $oldVer = "unknown"
    if ($isUpdate -and (Test-Path (Join-Path $appDir "VERSION"))) {
        $oldVer = (Get-Content (Join-Path $appDir "VERSION") -Raw).Trim()
    }

    Write-Host ""
    Write-Host "PSRoutes installer" -ForegroundColor Cyan
    Write-Host ""

    if ($isUpdate) {
        Write-Host "Existing install found (v$oldVer). Checking for updates..." -ForegroundColor Cyan
        Write-Host "Your routes, settings and local.ps1 will be kept." -ForegroundColor DarkGray
        Write-Host ""
    } else {
        Write-Host "This will create (or replace) your PowerShell profile at:"
        foreach ($t in $targets) { Write-Host "  $t" -ForegroundColor Yellow }
        Write-Host "An existing profile will be backed up as .bak first."
        Write-Host ""
        $answer = Read-Host "Continue? (Y/N)"
        if ($answer -notmatch '^[Yy]') {
            Write-Host "Cancelled. Nothing was changed." -ForegroundColor Yellow
            return
        }
    }

    # Kalau run dari repo yang dah clone, guna folder tu. Kalau tak, download.
    $newVer = "unknown"
    if ($fromClone) {
        $appDir = $PSScriptRoot
        if (Test-Path (Join-Path $appDir "VERSION")) { $newVer = (Get-Content (Join-Path $appDir "VERSION") -Raw).Trim() }
    } else {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $tmpZip  = Join-Path $env:TEMP "$Repo.zip"
        $tmpDir  = Join-Path $env:TEMP "$Repo-extract"

        Write-Host "Downloading $Owner/$Repo ..." -ForegroundColor Cyan
        Invoke-WebRequest -Uri "https://github.com/$Owner/$Repo/archive/refs/heads/$Branch.zip" -OutFile $tmpZip -UseBasicParsing
        if (Test-Path $tmpDir) { Remove-Item $tmpDir -Recurse -Force }
        Expand-Archive -Path $tmpZip -DestinationPath $tmpDir -Force

        $extracted = Join-Path $tmpDir "$Repo-$Branch"
        if (Test-Path (Join-Path $extracted "VERSION")) { $newVer = (Get-Content (Join-Path $extracted "VERSION") -Raw).Trim() }

        if ($isUpdate -and $newVer -eq $oldVer) {
            Remove-Item $tmpZip, $tmpDir -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "Already up to date (v$oldVer). Nothing to do." -ForegroundColor Green
            return
        }

        if (-not (Test-Path $dataDir)) { New-Item -ItemType Directory -Path $dataDir -Force | Out-Null }
        if (Test-Path $appDir) { Remove-Item $appDir -Recurse -Force }
        Move-Item $extracted $appDir
        Remove-Item $tmpZip, $tmpDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    $main = Join-Path $appDir $ProfileFile
    $stub = ". `"$main`""

    foreach ($t in $targets) {
        $dir = Split-Path $t -Parent
        if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }

        $existing = if (Test-Path $t) { Get-Content $t -Raw } else { $null }
        if ($existing -and $existing.Trim() -and $existing -notmatch [regex]::Escape($ProfileFile)) {
            Copy-Item $t "$t.bak" -Force
            Write-Host "Old profile backed up: $t.bak" -ForegroundColor Yellow
        }

        Set-Content -Path $t -Value $stub -Encoding UTF8
        Write-Host "Profile installed: $t" -ForegroundColor Green
    }

    try { Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force } catch {}

    # force a fresh update check next time "list" runs
    Remove-Item (Join-Path $dataDir "update-check.json") -Force -ErrorAction SilentlyContinue

    Write-Host ""
    if ($isUpdate) {
        Write-Host "Updated PSRoutes: v$oldVer -> v$newVer" -ForegroundColor Green
    } else {
        Write-Host "Thank you for installing PSRoutes! (v$newVer)" -ForegroundColor Cyan
        Write-Host "I made this just for fun, so please use it, change it and"
        Write-Host "customize it however you like. Make it yours."
        Write-Host "Love you all! - Shakir (Hanricus)" -ForegroundColor Magenta
    }
    Write-Host ""

    Write-Host "Let's test it. How do you want to run 'list'?" -ForegroundColor Cyan
    Write-Host "  [1] Open a new PowerShell window (recommended)"
    Write-Host "  [2] Reload the profile in this window"
    Write-Host "  [N] Skip"
    $choice = Read-Host "Choose 1 / 2 / N"

    if ($choice -eq "1") {
        $exe = if (Get-Command pwsh -ErrorAction SilentlyContinue) { "pwsh" } else { "powershell" }
        Start-Process $exe -ArgumentList "-NoExit", "-Command", "list"
    }

    # option 2 is run below, outside the function, so it loads into the current session
    $global:PSRoutesChoice = $choice
    $global:PSRoutesMain   = $main

    Write-Host ""
    Write-Host "Done." -ForegroundColor Cyan
}

Install-PSRoutes

if ($global:PSRoutesChoice -eq "2") { . $global:PSRoutesMain; list }
Remove-Variable PSRoutesChoice, PSRoutesMain -Scope Global -ErrorAction SilentlyContinue
