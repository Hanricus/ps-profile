# Cara 1 (tanpa buka web): tampal dalam PowerShell
#   irm https://raw.githubusercontent.com/Hanricus/ps-profile/main/install.ps1 | iex
# Cara 2: git clone repo, lepas tu run .\install.ps1
# Run baris yang sama lagi sekali untuk update.

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

    Write-Host ""
    Write-Host "PSRoutes installer" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "This will create (or replace) your PowerShell profile at:"
    foreach ($t in $targets) { Write-Host "  $t" -ForegroundColor Yellow }
    Write-Host "An existing profile will be backed up as .bak first."
    Write-Host ""
    $answer = Read-Host "Continue? (Y/N)"
    if ($answer -notmatch '^[Yy]') {
        Write-Host "Cancelled. Nothing was changed." -ForegroundColor Yellow
        return
    }

    # Kalau run dari repo yang dah clone, guna folder tu. Kalau tak, download.
    if ($PSScriptRoot -and (Test-Path (Join-Path $PSScriptRoot $ProfileFile))) {
        $appDir = $PSScriptRoot
    } else {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $dataDir = Join-Path $env:USERPROFILE "PSRoutes"
        $appDir  = Join-Path $dataDir "app"
        $tmpZip  = Join-Path $env:TEMP "$Repo.zip"
        $tmpDir  = Join-Path $env:TEMP "$Repo-extract"

        Write-Host "Downloading $Owner/$Repo ..." -ForegroundColor Cyan
        Invoke-WebRequest -Uri "https://github.com/$Owner/$Repo/archive/refs/heads/$Branch.zip" -OutFile $tmpZip -UseBasicParsing
        if (Test-Path $tmpDir) { Remove-Item $tmpDir -Recurse -Force }
        Expand-Archive -Path $tmpZip -DestinationPath $tmpDir -Force

        if (-not (Test-Path $dataDir)) { New-Item -ItemType Directory -Path $dataDir -Force | Out-Null }
        if (Test-Path $appDir) { Remove-Item $appDir -Recurse -Force }
        Move-Item (Join-Path $tmpDir "$Repo-$Branch") $appDir
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

    Write-Host ""
    Write-Host "Thank you for installing PSRoutes!" -ForegroundColor Cyan
    Write-Host "I made this just for fun, so please use it, change it and"
    Write-Host "customize it however you like. Make it yours."
    Write-Host "Love you all! - Shakir (Hanricus)" -ForegroundColor Magenta
    Write-Host ""

    $open = Read-Host "Do you want to open the code now to take a look? (Y/N)"
    if ($open -match '^[Yy]') {
        if (Get-Command code -ErrorAction SilentlyContinue) {
            & code $main
        } else {
            Start-Process notepad.exe -ArgumentList "`"$main`""
        }
    }

    Write-Host ""
    Write-Host "Done. Close this window and open a new PowerShell." -ForegroundColor Cyan
}

Install-PSRoutes
