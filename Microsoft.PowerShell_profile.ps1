# PSRoutes by Shakir (Hanricus) - https://github.com/Hanricus/ps-profile
# Made just for fun. Use it, change it, make it your own. MIT License.

# ===== MACHINE CONFIG (auto-detect, tak payah edit) =====
$global:PSDataDir = Join-Path $env:USERPROFILE "PSRoutes"
if (-not (Test-Path $global:PSDataDir)) { New-Item -ItemType Directory -Path $global:PSDataDir -Force | Out-Null }

# backup script: cari dalam PSRoutes dulu, lepas tu D:\
$global:BackupScript = @((Join-Path $global:PSDataDir "backup.ps1"), "D:\backup.ps1") | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $global:BackupScript) { $global:BackupScript = Join-Path $global:PSDataDir "backup.ps1" }

# PHP: cari folder C:\php* paling baru yang ada php.exe, kalau jumpa letak depan PATH
$phpDir = Get-ChildItem "C:\" -Directory -Filter "php*" -ErrorAction SilentlyContinue |
    Where-Object { Test-Path (Join-Path $_.FullName "php.exe") } |
    Sort-Object Name -Descending | Select-Object -First 1
if ($phpDir) { $env:Path = "$($phpDir.FullName);" + $env:Path }

# ============================================
# DYNAMIC ROUTE SYSTEM - alias untuk network path
# Tambah route baru: type "newpath"
# Tengok semua route: type "list"
# ============================================
$global:routesFile = Join-Path $global:PSDataDir "ps-routes.json"
if (-not (Test-Path $global:routesFile) -and (Test-Path "D:\ps-routes.json")) { Copy-Item "D:\ps-routes.json" $global:routesFile }
$global:availableLetters = @("V","W","X","Y","Z","U","T","S","R","Q")

function Invoke-RouteConnect {
    param(
        [string]$aliasName,
        [string]$server,       # contoh: \\server01\share
        [string]$targetSubPath, # contoh: myapp  (boleh kosong "")
        [string]$driveLetter    # contoh: "V:"
    )

    $localBackupScript = $global:BackupScript
    $foundDrive = $null
    $targetPath = $null

    Write-Host ""
    Write-Host "Searching for available network drive..." -ForegroundColor Cyan

    # 1. Check if already in target directory
    $currentLocation = Get-Location
    $matchPattern = if ($targetSubPath -ne "") { [Regex]::Escape("\$targetSubPath") } else { $null }
    if ($matchPattern -and $currentLocation.Path -match $matchPattern) {
        if ($currentLocation.Path -match "^([A-Z]:)") {
            $foundDrive = $matches[1]
            $targetPath = $currentLocation.Path
            Write-Host "Already in $aliasName directory: $targetPath" -ForegroundColor Green
        }
    }

    # 2. Try to detect existing mapped drives
    if (-not $foundDrive) {
        $allDrives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Root -match "^\\\\" }
        foreach ($drive in $allDrives) {
            $testPath = if ($targetSubPath -ne "") { Join-Path "$($drive.Name):" $targetSubPath } else { "$($drive.Name):\" }
            if (Test-Path $testPath) {
                $foundDrive = "$($drive.Name):"
                $targetPath = $testPath
                Write-Host "Found existing mapped drive: $foundDrive" -ForegroundColor Green
                break
            }
        }
    }

    # 3. If still not found, map fresh using assigned drive letter
    if (-not $foundDrive) {
        $hostName = ($server -replace "\\\\", "") -split "\\" | Select-Object -First 1
        Write-Host "Checking connection to $hostName..." -ForegroundColor Yellow

        if (-not (Test-Connection -ComputerName $hostName -Count 1 -Quiet -ErrorAction SilentlyContinue)) {
            Write-Host "$hostName not reachable." -ForegroundColor Red
        } else {
            Write-Host "Attempting to map temporary drive for $server..." -ForegroundColor Yellow
            $tempLetter = $driveLetter

            try {
                $existingDrive = Get-PSDrive -Name ($tempLetter.TrimEnd(":")) -ErrorAction SilentlyContinue
                if ($existingDrive) {
                    Write-Host "$tempLetter drive already mapped, checking if valid..." -ForegroundColor Yellow
                    $testPath = if ($targetSubPath -ne "") { Join-Path $tempLetter $targetSubPath } else { "$tempLetter\" }
                    if (Test-Path $testPath) {
                        $foundDrive = $tempLetter
                        $targetPath = $testPath
                        Write-Host "$tempLetter drive is valid and accessible" -ForegroundColor Green
                    } else {
                        Write-Host "$tempLetter drive exists but path not found, trying to remap..." -ForegroundColor Yellow
                        Start-Process "net" -ArgumentList "use", $tempLetter, "/delete", "/yes" -WindowStyle Hidden -Wait -ErrorAction SilentlyContinue
                        Start-Sleep -Milliseconds 500
                    }
                }

                if (-not $foundDrive) {
                    Start-Process "net" -ArgumentList "use", $tempLetter, "/delete", "/yes" -WindowStyle Hidden -Wait -ErrorAction SilentlyContinue
                    Start-Sleep -Milliseconds 500

                    Start-Process "net" -ArgumentList "use", $tempLetter, $server, "/persistent:no" -WindowStyle Hidden -Wait -ErrorAction Stop
                    Start-Sleep -Seconds 2

                    $testPath = if ($targetSubPath -ne "") { Join-Path $tempLetter $targetSubPath } else { "$tempLetter\" }
                    if (Test-Path $testPath) {
                        $foundDrive = $tempLetter
                        $targetPath = $testPath
                        Write-Host "Successfully mapped $tempLetter to $server" -ForegroundColor Green
                    } else {
                        Write-Host "Path $testPath not found." -ForegroundColor Yellow
                        Start-Process "net" -ArgumentList "use", $tempLetter, "/delete", "/yes" -WindowStyle Hidden -Wait -ErrorAction SilentlyContinue
                    }
                }
            } catch {
                Write-Host "Error mapping $server : $_" -ForegroundColor Red
            }
        }
    }

    if (-not $foundDrive -or -not $targetPath) {
        Write-Host ""
        Write-Host "ERROR: No valid network drive found. Check connection or server access." -ForegroundColor Red
        Write-Host ""
        return
    }

    if ($currentLocation.Path -ne $targetPath) {
        Set-Location $targetPath
        Write-Host ""
        Write-Host "SUCCESS: Navigated to $targetPath" -ForegroundColor Green
        Write-Host ""
    } else {
        Write-Host ""
    }
}

function Invoke-LocalRoute {
    param([string]$aliasName, [string]$path)
    if (-not (Test-Path -LiteralPath $path)) {
        Write-Host "ERROR: $path tak jumpa." -ForegroundColor Red
        return
    }
    if (Test-Path -LiteralPath $path -PathType Container) {
        Set-Location -LiteralPath $path
        Write-Host "SUCCESS: Navigated to $path" -ForegroundColor Green
    } elseif ([IO.Path]::GetExtension($path) -eq ".ps1") {
        & $path
    } else {
        Write-Host "Opening $aliasName..." -ForegroundColor Cyan
        if ([IO.Path]::GetExtension($path) -in ".bat", ".cmd") {
            cmd /c "`"$path`""
        } else {
            Start-Process -FilePath $path -WorkingDirectory (Split-Path $path -Parent)
        }
    }
}

function Register-LocalRouteFunction {
    param([string]$aliasName, [string]$path)
    $safePath = $path -replace "'", "''"
    Invoke-Expression "function global:$aliasName { Invoke-LocalRoute -aliasName '$aliasName' -path '$safePath' }"
}

function Register-RouteFunction {
    param(
        [string]$aliasName,
        [string]$server,
        [string]$targetSubPath,
        [string]$driveLetter
    )
    Invoke-Expression @"
function global:$aliasName {
    Invoke-RouteConnect -aliasName '$aliasName' -server '$server' -targetSubPath '$targetSubPath' -driveLetter '$driveLetter'
}
"@
}

function Split-RoutePath {
    param([string]$fullPath)
    # \\server\share\rest\of\path  ->  server = \\server\share , subPath = rest\of\path
    $parts = $fullPath.Trim('\') -split '\\'
    if ($parts.Count -lt 2) { return $null }
    $server = "\\" + $parts[0] + "\" + $parts[1]
    $subPath = if ($parts.Count -gt 2) { ($parts[2..($parts.Count-1)] -join '\') } else { "" }
    return [PSCustomObject]@{ Server = $server; SubPath = $subPath }
}

function Get-NextFreeLetter {
    param($usedLetters)
    foreach ($letter in $global:availableLetters) {
        if ($usedLetters -notcontains $letter) { return "$($letter):" }
    }
    return "Y:" # fallback
}

function Load-Routes {
    if (Test-Path $global:routesFile) {
        $routes = Get-Content $global:routesFile -Raw | ConvertFrom-Json
        $migratedRoutes = @{}
        $needsSave = $false
        $usedLetters = @()

        # First pass: collect drive letters already assigned (new format only)
        $routes.PSObject.Properties | ForEach-Object {
            if ($_.Value -is [PSCustomObject] -and $_.Value.DriveLetter) {
                $usedLetters += ($_.Value.DriveLetter -replace ":", "")
            }
        }

        $routes.PSObject.Properties | ForEach-Object {
            $aliasName = $_.Name
            $routeData = $_.Value

            if ($routeData -is [string]) {
                # OLD FORMAT detected (plain path string) -> auto-migrate
                Write-Host "Migrating old route '$aliasName'..." -ForegroundColor DarkYellow
                $split = Split-RoutePath -fullPath $routeData
                if ($split) {
                    $driveLetter = Get-NextFreeLetter -usedLetters $usedLetters
                    $usedLetters += ($driveLetter -replace ":", "")
                    $newRouteObj = [PSCustomObject]@{
                        Server      = $split.Server
                        SubPath     = $split.SubPath
                        DriveLetter = $driveLetter
                    }
                    $migratedRoutes[$aliasName] = $newRouteObj
                    Register-RouteFunction -aliasName $aliasName -server $split.Server -targetSubPath $split.SubPath -driveLetter $driveLetter
                    $needsSave = $true
                } else {
                    Write-Host "WARNING: Route '$aliasName' tak boleh migrate (format path tak valid), skip." -ForegroundColor Red
                }
            } else {
                # NEW FORMAT already
                                $migratedRoutes[$aliasName] = $routeData
                if ($routeData.Type -eq "local") {
                    Register-LocalRouteFunction -aliasName $aliasName -path $routeData.Path
                } else {
                    Register-RouteFunction -aliasName $aliasName -server $routeData.Server -targetSubPath $routeData.SubPath -driveLetter $routeData.DriveLetter
                }
            }
        }

        if ($needsSave) {
            $migratedRoutes | ConvertTo-Json | Set-Content $global:routesFile
            Write-Host "SUCCESS: Semua route lama dah auto-migrate ke format baru." -ForegroundColor Green
        }
    } else {
        @{} | ConvertTo-Json | Set-Content $global:routesFile
    }
}

function newpath {
    Write-Host ""
    $path = Read-Host "Paste path routes (contoh: \\server01\share\myapp)"
    $path = $path.Trim().Trim('"')

    if (-not (Test-Path $path)) {
        Write-Host "WARNING: Path ni tak jumpa/tak boleh access dari sini." -ForegroundColor Yellow
        $confirm = Read-Host "Confirm nak simpan jugak? (Y/N)"
        if ($confirm -ne "Y" -and $confirm -ne "y") {
            Write-Host "Cancelled." -ForegroundColor Red
            return
        }
    }

    if ($path -notmatch '^\\\\') {
        $aliasName = Read-Host "Nak letak alias apa untuk file/folder ni? (contoh: watermark)"
        $routes = @{}
        if (Test-Path $global:routesFile) {
            $existing = Get-Content $global:routesFile -Raw | ConvertFrom-Json
            $existing.PSObject.Properties | ForEach-Object { $routes[$_.Name] = $_.Value }
        }
        $routes[$aliasName] = [PSCustomObject]@{ Type = "local"; Path = $path }
        $routes | ConvertTo-Json | Set-Content $global:routesFile
        Register-LocalRouteFunction -aliasName $aliasName -path $path
        Write-Host ""
        Write-Host "SUCCESS: Alias '$aliasName' -> $path (local)" -ForegroundColor Green
        Write-Host "Type '$aliasName' untuk run/buka." -ForegroundColor Cyan
        Write-Host ""
        return
    }

    $split = Split-RoutePath -fullPath $path
    if (-not $split) {
        Write-Host "ERROR: Path format tak valid. Kena format \\server\share\..." -ForegroundColor Red
        return
    }

    $aliasName = Read-Host "Nak letak alias apa untuk route ni? (contoh: myapp)"

    $routes = @{}
    $usedLetters = @()
    if (Test-Path $global:routesFile) {
        $existing = Get-Content $global:routesFile -Raw | ConvertFrom-Json
        $existing.PSObject.Properties | ForEach-Object {
            $routes[$_.Name] = $_.Value
            $usedLetters += ($_.Value.DriveLetter -replace ":", "")
        }
    }

    if ($routes.ContainsKey($aliasName)) {
        Write-Host "WARNING: Alias '$aliasName' dah wujud, overwrite path lama." -ForegroundColor Yellow
        $usedLetters = $usedLetters | Where-Object { $_ -ne ($routes[$aliasName].DriveLetter -replace ":", "") }
    }

    $driveLetter = Get-NextFreeLetter -usedLetters $usedLetters

    $routeObj = [PSCustomObject]@{
        Server      = $split.Server
        SubPath     = $split.SubPath
        DriveLetter = $driveLetter
    }
    $routes[$aliasName] = $routeObj
    $routes | ConvertTo-Json | Set-Content $global:routesFile

    Register-RouteFunction -aliasName $aliasName -server $split.Server -targetSubPath $split.SubPath -driveLetter $driveLetter

    Write-Host ""
    Write-Host "SUCCESS: Alias '$aliasName' -> $($split.Server)\$($split.SubPath) (drive $driveLetter)" -ForegroundColor Green
    Write-Host "Boleh terus type '$aliasName' untuk masuk folder ni bila-bila masa." -ForegroundColor Cyan
    Write-Host ""
}

function scanmuka {
    $scriptPath = Join-Path ([Environment]::GetFolderPath("Desktop")) "ScanMuka\App.py"
    if (Test-Path $scriptPath) {
        Write-Host ""
        Write-Host "Running ScanMuka..." -ForegroundColor Cyan
        python $scriptPath
    } else {
        Write-Host "ERROR: File tak jumpa kat $scriptPath" -ForegroundColor Red
    }
}

function list {
        $bootLines = @("[*] Initializing route table...", "[*] Decrypting alias map...", "[*] Access granted.")
    foreach ($line in $bootLines) {
        Write-Host $line -ForegroundColor DarkGreen
        Start-Sleep -Milliseconds 200
    }
    Write-Host ""
    Write-Host ""
    Write-Host "  ____   ___  _   _ _____ _____ ____  " -ForegroundColor Green
    Write-Host " |  _ \ / _ \| | | |_   _| ____/ ___| " -ForegroundColor Green
    Write-Host " | |_) | | | | | | | | | |  _| \___ \ " -ForegroundColor Green
    Write-Host " |  _ <| |_| | |_| | | | | |___ ___) |" -ForegroundColor Green
    Write-Host " |_| \_\\___/ \___/  |_| |_____|____/ " -ForegroundColor Green
    Write-Host ""
    if ($global:LegacyRouteInfo) {
        Write-Host "=== ROUTES (LOCAL - dari local.ps1) ===" -ForegroundColor Cyan
        foreach ($info in $global:LegacyRouteInfo) {
            Write-Host "  $($info.Name)" -ForegroundColor Green -NoNewline
            Write-Host " -> $($info.Target)" -ForegroundColor DarkGray
        }
    }
    Write-Host ""
    Write-Host "=== ROUTES (BARU - dari newpath) ===" -ForegroundColor Cyan
    $hasRoutes = $false
    if (Test-Path $global:routesFile) {
        $routes = Get-Content $global:routesFile -Raw | ConvertFrom-Json
        $routes.PSObject.Properties | ForEach-Object {
            $hasRoutes = $true
            Write-Host "  $($_.Name)" -ForegroundColor Green -NoNewline
            if ($_.Value.Type -eq "local") {
                Write-Host " -> $($_.Value.Path) [local]" -ForegroundColor DarkGray
            } else {
                Write-Host " -> $($_.Value.Server)\$($_.Value.SubPath) [drive $($_.Value.DriveLetter)]" -ForegroundColor DarkGray
            }
        }
    }
    if (-not $hasRoutes) {
        Write-Host "  (takde lagi)" -ForegroundColor DarkGray
    }
    Write-Host ""
    Write-Host "  newpath" -ForegroundColor Yellow -NoNewline
    Write-Host " -> tambah route baru" -ForegroundColor DarkGray
    Write-Host ""
}

# Load private extras (tak masuk git): %USERPROFILE%\PSRoutes\local.ps1
$localExtras = Join-Path $global:PSDataDir "local.ps1"
if (Test-Path $localExtras) { . $localExtras }

# Load semua saved routes bila terminal start
Load-Routes