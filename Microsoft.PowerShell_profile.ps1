# PSRoutes by Shakir (Hanricus) - https://github.com/Hanricus/ps-profile
# Made just for fun. Use it, change it, make it your own. MIT License.

# ===== MACHINE CONFIG (auto-detect, no need to edit) =====
$global:PSDataDir = Join-Path $env:USERPROFILE "PSRoutes"
if (-not (Test-Path $global:PSDataDir)) { New-Item -ItemType Directory -Path $global:PSDataDir -Force | Out-Null }

# ===== LANGUAGE (EN / MY) =====
# Default is EN. Type "lang my" or "lang en" to switch; the choice is saved in PSRoutes\config.json
$global:configFile = Join-Path $global:PSDataDir "config.json"
$global:PSLang = "EN"
if (Test-Path $global:configFile) {
    try {
        $cfg = Get-Content $global:configFile -Raw | ConvertFrom-Json
        if ($cfg.Lang -in @("EN", "MY")) { $global:PSLang = $cfg.Lang }
    } catch { }
}

$global:Msg = @{
    EN = @{
        Searching        = "Searching for available network drive..."
        AlreadyIn        = "Already in {0} directory: {1}"
        FoundDrive       = "Found existing mapped drive: {0}"
        CheckingConn     = "Checking connection to {0}..."
        NotReachable     = "{0} not reachable."
        Mapping          = "Attempting to map temporary drive for {0}..."
        DriveMapped      = "{0} drive already mapped, checking if valid..."
        DriveValid       = "{0} drive is valid and accessible"
        DriveRemap       = "{0} drive exists but path not found, trying to remap..."
        MapOk            = "Successfully mapped {0} to {1}"
        PathNotFound     = "Path {0} not found."
        MapError         = "Error mapping {0} : {1}"
        NoDrive          = "ERROR: No valid network drive found. Check connection or server access."
        Navigated        = "SUCCESS: Navigated to {0}"
        NotFound         = "ERROR: {0} not found."
        Opening          = "Opening {0}..."
        Migrating        = "Migrating old route '{0}'..."
        MigrateFail      = "WARNING: Route '{0}' cannot be migrated (invalid path format), skipped."
        MigrateDone      = "SUCCESS: All old routes were auto-migrated to the new format."
        PastePath        = "Paste route path (example: \\server01\share\myapp)"
        PathWarn         = "WARNING: This path was not found / cannot be accessed from here."
        ConfirmSave      = "Save it anyway? (Y/N)"
        Cancelled        = "Cancelled."
        AliasLocalPrompt = "What alias do you want for this file/folder? (example: watermark)"
        AliasLocalOk     = "SUCCESS: Alias '{0}' -> {1} (local)"
        TypeToRun        = "Type '{0}' to run/open it."
        BadFormat        = "ERROR: Invalid path format. Must be \\server\share\..."
        AliasRoutePrompt = "What alias do you want for this route? (example: myapp)"
        AliasExists      = "WARNING: Alias '{0}' already exists, overwriting the old path."
        AliasRouteOk     = "SUCCESS: Alias '{0}' -> {1} (drive {2})"
        TypeToEnter      = "You can now type '{0}' anytime to enter this folder."
        RunningScan      = "Running ScanMuka..."
        FileNotFound     = "ERROR: File not found at {0}"
        HdrLocal         = "=== ROUTES (LOCAL - from local.ps1) ==="
        HdrNew           = "=== ROUTES (NEW - from newpath) ==="
        NoneYet          = "(none yet)"
        AddRoute         = "-> add a new route"
        LangCurrent      = "Current language: {0}"
        LangUsage        = "Usage: lang en | lang my"
        LangSet          = "Language set to {0}"
    }
    MY = @{
        Searching        = "Mencari network drive yang ada..."
        AlreadyIn        = "Dah berada dalam folder {0}: {1}"
        FoundDrive       = "Jumpa drive yang dah di-map: {0}"
        CheckingConn     = "Menyemak sambungan ke {0}..."
        NotReachable     = "{0} tak dapat dicapai."
        Mapping          = "Cuba map drive sementara untuk {0}..."
        DriveMapped      = "Drive {0} dah di-map, semak sama ada sah..."
        DriveValid       = "Drive {0} sah dan boleh diakses"
        DriveRemap       = "Drive {0} wujud tapi path tak jumpa, cuba map semula..."
        MapOk            = "Berjaya map {0} ke {1}"
        PathNotFound     = "Path {0} tak jumpa."
        MapError         = "Ralat semasa map {0} : {1}"
        NoDrive          = "ERROR: Tiada network drive yang sah. Semak sambungan atau akses server."
        Navigated        = "SUCCESS: Dah masuk ke {0}"
        NotFound         = "ERROR: {0} tak jumpa."
        Opening          = "Membuka {0}..."
        Migrating        = "Migrate route lama '{0}'..."
        MigrateFail      = "WARNING: Route '{0}' tak boleh migrate (format path tak valid), skip."
        MigrateDone      = "SUCCESS: Semua route lama dah auto-migrate ke format baru."
        PastePath        = "Paste path route (contoh: \\server01\share\myapp)"
        PathWarn         = "WARNING: Path ni tak jumpa / tak boleh access dari sini."
        ConfirmSave      = "Confirm nak simpan jugak? (Y/N)"
        Cancelled        = "Dibatalkan."
        AliasLocalPrompt = "Nak letak alias apa untuk file/folder ni? (contoh: watermark)"
        AliasLocalOk     = "SUCCESS: Alias '{0}' -> {1} (local)"
        TypeToRun        = "Type '{0}' untuk run/buka."
        BadFormat        = "ERROR: Format path tak valid. Kena format \\server\share\..."
        AliasRoutePrompt = "Nak letak alias apa untuk route ni? (contoh: myapp)"
        AliasExists      = "WARNING: Alias '{0}' dah wujud, overwrite path lama."
        AliasRouteOk     = "SUCCESS: Alias '{0}' -> {1} (drive {2})"
        TypeToEnter      = "Boleh terus type '{0}' untuk masuk folder ni bila-bila masa."
        RunningScan      = "Menjalankan ScanMuka..."
        FileNotFound     = "ERROR: File tak jumpa kat {0}"
        HdrLocal         = "=== ROUTES (LOCAL - dari local.ps1) ==="
        HdrNew           = "=== ROUTES (BARU - dari newpath) ==="
        NoneYet          = "(takde lagi)"
        AddRoute         = "-> tambah route baru"
        LangCurrent      = "Bahasa semasa: {0}"
        LangUsage        = "Guna: lang en | lang my"
        LangSet          = "Bahasa ditukar ke {0}"
    }
}

# Tr = translate. Usage: Tr 'Navigated' $path   (falls back to EN, then to the key itself)
function Tr {
    param([string]$key)
    $fmt = $global:Msg[$global:PSLang][$key]
    if (-not $fmt) { $fmt = $global:Msg["EN"][$key] }
    if (-not $fmt) { return $key }
    if ($args.Count -gt 0) { return ($fmt -f $args) }
    return $fmt
}

function lang {
    param([string]$code = "")
    $code = $code.ToUpper()
    if ($code -notin @("EN", "MY")) {
        Write-Host (Tr 'LangCurrent' $global:PSLang) -ForegroundColor Cyan
        Write-Host (Tr 'LangUsage') -ForegroundColor DarkGray
        return
    }
    $global:PSLang = $code
    @{ Lang = $code } | ConvertTo-Json | Set-Content $global:configFile
    Write-Host (Tr 'LangSet' $code) -ForegroundColor Green
}

# backup script: look in PSRoutes first, then D:\
$global:BackupScript = @((Join-Path $global:PSDataDir "backup.ps1"), "D:\backup.ps1") | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $global:BackupScript) { $global:BackupScript = Join-Path $global:PSDataDir "backup.ps1" }

# PHP: find the newest C:\php* folder containing php.exe and put it first in PATH
$phpDir = Get-ChildItem "C:\" -Directory -Filter "php*" -ErrorAction SilentlyContinue |
    Where-Object { Test-Path (Join-Path $_.FullName "php.exe") } |
    Sort-Object Name -Descending | Select-Object -First 1
if ($phpDir) { $env:Path = "$($phpDir.FullName);" + $env:Path }

# ============================================
# DYNAMIC ROUTE SYSTEM - aliases for network paths / local files
# Add a new route: type "newpath"
# See all routes:  type "list"
# ============================================
$global:routesFile = Join-Path $global:PSDataDir "ps-routes.json"
if (-not (Test-Path $global:routesFile) -and (Test-Path "D:\ps-routes.json")) { Copy-Item "D:\ps-routes.json" $global:routesFile }
$global:availableLetters = @("V","W","X","Y","Z","U","T","S","R","Q")

function Invoke-RouteConnect {
    param(
        [string]$aliasName,
        [string]$server,       # example: \\server01\share
        [string]$targetSubPath, # example: myapp  (can be empty "")
        [string]$driveLetter    # example: "V:"
    )

    $localBackupScript = $global:BackupScript
    $foundDrive = $null
    $targetPath = $null

    Write-Host ""
    Write-Host (Tr 'Searching') -ForegroundColor Cyan

    # 1. Check if already in target directory
    $currentLocation = Get-Location
    $matchPattern = if ($targetSubPath -ne "") { [Regex]::Escape("\$targetSubPath") } else { $null }
    if ($matchPattern -and $currentLocation.Path -match $matchPattern) {
        if ($currentLocation.Path -match "^([A-Z]:)") {
            $foundDrive = $matches[1]
            $targetPath = $currentLocation.Path
            Write-Host (Tr 'AlreadyIn' $aliasName $targetPath) -ForegroundColor Green
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
                Write-Host (Tr 'FoundDrive' $foundDrive) -ForegroundColor Green
                break
            }
        }
    }

    # 3. If still not found, map fresh using assigned drive letter
    if (-not $foundDrive) {
        $hostName = ($server -replace "\\\\", "") -split "\\" | Select-Object -First 1
        Write-Host (Tr 'CheckingConn' $hostName) -ForegroundColor Yellow

        if (-not (Test-Connection -ComputerName $hostName -Count 1 -Quiet -ErrorAction SilentlyContinue)) {
            Write-Host (Tr 'NotReachable' $hostName) -ForegroundColor Red
        } else {
            Write-Host (Tr 'Mapping' $server) -ForegroundColor Yellow
            $tempLetter = $driveLetter

            try {
                $existingDrive = Get-PSDrive -Name ($tempLetter.TrimEnd(":")) -ErrorAction SilentlyContinue
                if ($existingDrive) {
                    Write-Host (Tr 'DriveMapped' $tempLetter) -ForegroundColor Yellow
                    $testPath = if ($targetSubPath -ne "") { Join-Path $tempLetter $targetSubPath } else { "$tempLetter\" }
                    if (Test-Path $testPath) {
                        $foundDrive = $tempLetter
                        $targetPath = $testPath
                        Write-Host (Tr 'DriveValid' $tempLetter) -ForegroundColor Green
                    } else {
                        Write-Host (Tr 'DriveRemap' $tempLetter) -ForegroundColor Yellow
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
                        Write-Host (Tr 'MapOk' $tempLetter $server) -ForegroundColor Green
                    } else {
                        Write-Host (Tr 'PathNotFound' $testPath) -ForegroundColor Yellow
                        Start-Process "net" -ArgumentList "use", $tempLetter, "/delete", "/yes" -WindowStyle Hidden -Wait -ErrorAction SilentlyContinue
                    }
                }
            } catch {
                Write-Host (Tr 'MapError' $server $_) -ForegroundColor Red
            }
        }
    }

    if (-not $foundDrive -or -not $targetPath) {
        Write-Host ""
        Write-Host (Tr 'NoDrive') -ForegroundColor Red
        Write-Host ""
        return
    }

    if ($currentLocation.Path -ne $targetPath) {
        Set-Location $targetPath
        Write-Host ""
        Write-Host (Tr 'Navigated' $targetPath) -ForegroundColor Green
        Write-Host ""
    } else {
        Write-Host ""
    }
}

function Invoke-LocalRoute {
    param([string]$aliasName, [string]$path)
    if (-not (Test-Path -LiteralPath $path)) {
        Write-Host (Tr 'NotFound' $path) -ForegroundColor Red
        return
    }
    if (Test-Path -LiteralPath $path -PathType Container) {
        Set-Location -LiteralPath $path
        Write-Host (Tr 'Navigated' $path) -ForegroundColor Green
    } elseif ([IO.Path]::GetExtension($path) -eq ".ps1") {
        & $path
    } else {
        Write-Host (Tr 'Opening' $aliasName) -ForegroundColor Cyan
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
                Write-Host (Tr 'Migrating' $aliasName) -ForegroundColor DarkYellow
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
                    Write-Host (Tr 'MigrateFail' $aliasName) -ForegroundColor Red
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
            Write-Host (Tr 'MigrateDone') -ForegroundColor Green
        }
    } else {
        @{} | ConvertTo-Json | Set-Content $global:routesFile
    }
}

function newpath {
    Write-Host ""
    $path = Read-Host (Tr 'PastePath')
    $path = $path.Trim().Trim('"')

    if (-not (Test-Path $path)) {
        Write-Host (Tr 'PathWarn') -ForegroundColor Yellow
        $confirm = Read-Host (Tr 'ConfirmSave')
        if ($confirm -ne "Y" -and $confirm -ne "y") {
            Write-Host (Tr 'Cancelled') -ForegroundColor Red
            return
        }
    }

    if ($path -notmatch '^\\\\') {
        $aliasName = Read-Host (Tr 'AliasLocalPrompt')
        $routes = @{}
        if (Test-Path $global:routesFile) {
            $existing = Get-Content $global:routesFile -Raw | ConvertFrom-Json
            $existing.PSObject.Properties | ForEach-Object { $routes[$_.Name] = $_.Value }
        }
        $routes[$aliasName] = [PSCustomObject]@{ Type = "local"; Path = $path }
        $routes | ConvertTo-Json | Set-Content $global:routesFile
        Register-LocalRouteFunction -aliasName $aliasName -path $path
        Write-Host ""
        Write-Host (Tr 'AliasLocalOk' $aliasName $path) -ForegroundColor Green
        Write-Host (Tr 'TypeToRun' $aliasName) -ForegroundColor Cyan
        Write-Host ""
        return
    }

    $split = Split-RoutePath -fullPath $path
    if (-not $split) {
        Write-Host (Tr 'BadFormat') -ForegroundColor Red
        return
    }

    $aliasName = Read-Host (Tr 'AliasRoutePrompt')

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
        Write-Host (Tr 'AliasExists' $aliasName) -ForegroundColor Yellow
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
    Write-Host (Tr 'AliasRouteOk' $aliasName "$($split.Server)\$($split.SubPath)" $driveLetter) -ForegroundColor Green
    Write-Host (Tr 'TypeToEnter' $aliasName) -ForegroundColor Cyan
    Write-Host ""
}

function scanmuka {
    $scriptPath = Join-Path ([Environment]::GetFolderPath("Desktop")) "ScanMuka\App.py"
    if (Test-Path $scriptPath) {
        Write-Host ""
        Write-Host (Tr 'RunningScan') -ForegroundColor Cyan
        python $scriptPath
    } else {
        Write-Host (Tr 'FileNotFound' $scriptPath) -ForegroundColor Red
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
        Write-Host (Tr 'HdrLocal') -ForegroundColor Cyan
        foreach ($info in $global:LegacyRouteInfo) {
            Write-Host "  $($info.Name)" -ForegroundColor Green -NoNewline
            Write-Host " -> $($info.Target)" -ForegroundColor DarkGray
        }
    }
    Write-Host ""
    Write-Host (Tr 'HdrNew') -ForegroundColor Cyan
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
        Write-Host "  $(Tr 'NoneYet')" -ForegroundColor DarkGray
    }
    Write-Host ""
    Write-Host "  newpath" -ForegroundColor Yellow -NoNewline
    Write-Host " $(Tr 'AddRoute')" -ForegroundColor DarkGray
    Write-Host ""
}

# Load private extras (not in git): %USERPROFILE%\PSRoutes\local.ps1
$localExtras = Join-Path $global:PSDataDir "local.ps1"
if (Test-Path $localExtras) { . $localExtras }

# Load all saved routes when the terminal starts
Load-Routes