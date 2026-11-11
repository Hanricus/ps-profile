# Cara 1 (tanpa buka web): tampal dalam PowerShell
#   irm https://raw.githubusercontent.com/Hanricus/ps-profile/main/install.ps1 | iex
# Cara 2: git clone repo, lepas tu run .\install.ps1
# Run baris yang sama lagi sekali untuk UPDATE. Route, setting dan local.ps1 kau tak disentuh.

function Get-FileLockers {
    param([string]$Path)
    try {
        if (-not ('PSRLock' -as [type])) {
            Add-Type -TypeDefinition @"
using System; using System.Text; using System.Collections.Generic; using System.Runtime.InteropServices;
public static class PSRLock {
    [StructLayout(LayoutKind.Sequential)] struct RM_UNIQUE_PROCESS { public int dwProcessId; public System.Runtime.InteropServices.ComTypes.FILETIME ProcessStartTime; }
    [StructLayout(LayoutKind.Sequential, CharSet=CharSet.Unicode)] struct RM_PROCESS_INFO {
        public RM_UNIQUE_PROCESS Process;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst=256)] public string strAppName;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst=64)] public string strServiceShortName;
        public int ApplicationType; public uint AppStatus; public uint TSSessionId;
        [MarshalAs(UnmanagedType.Bool)] public bool bRestartable;
    }
    [DllImport("rstrtmgr.dll", CharSet=CharSet.Unicode)] static extern int RmStartSession(out uint h, int flags, StringBuilder key);
    [DllImport("rstrtmgr.dll")] static extern int RmEndSession(uint h);
    [DllImport("rstrtmgr.dll", CharSet=CharSet.Unicode)] static extern int RmRegisterResources(uint h, uint nFiles, string[] files, uint nApps, RM_UNIQUE_PROCESS[] apps, uint nSvc, string[] svc);
    [DllImport("rstrtmgr.dll")] static extern int RmGetList(uint h, out uint needed, ref uint count, [In, Out] RM_PROCESS_INFO[] info, out uint reasons);
    public static string[] Who(string path) {
        var res = new List<string>(); uint h;
        var key = new StringBuilder(33);
        if (RmStartSession(out h, 0, key) != 0) return res.ToArray();
        try {
            RmRegisterResources(h, 1, new[] { path }, 0, null, 0, null);
            uint needed = 0, count = 0, reasons;
            int r = RmGetList(h, out needed, ref count, null, out reasons);
            if (r == 234 && needed > 0) {
                count = needed;
                var info = new RM_PROCESS_INFO[count];
                r = RmGetList(h, out needed, ref count, info, out reasons);
                if (r == 0) for (int i = 0; i < count; i++) res.Add(info[i].strAppName + " (PID " + info[i].Process.dwProcessId + ")");
            }
        } finally { RmEndSession(h); }
        return res.ToArray();
    }
}
"@
        }
        return [PSRLock]::Who($Path)
    } catch { return @() }
}

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
    Write-Host ' ____  ____    ____   ___  _   _ _____ _____ ____  ' -ForegroundColor Green
    Write-Host '|  _ \/ ___|  |  _ \ / _ \| | | |_   _| ____/ ___| ' -ForegroundColor Green
    Write-Host '| |_) \___ \  | |_) | | | | | | | | | |  _| \___ \ ' -ForegroundColor Green
    Write-Host '|  __/ ___) | |  _ <| |_| | |_| | | | | |___ ___) |' -ForegroundColor Green
    Write-Host '|_|   |____/  |_| \_\\___/ \___/  |_| |_____|____/ ' -ForegroundColor Green
    Write-Host '                                          ~ by yolo' -ForegroundColor DarkGray
    Write-Host ""

    if ($isUpdate) {
        Write-Host "Existing install found (v$oldVer). Checking for updates..." -ForegroundColor Cyan
        Write-Host "Your routes, settings and local.ps1 will be kept." -ForegroundColor DarkGray
        Write-Host ""
    } else {
        Write-Host "Installing PSRoutes to:" -ForegroundColor Cyan
        foreach ($t in $targets) { Write-Host "  $t" -ForegroundColor Yellow }
        Write-Host "Existing profile (if any) is backed up as .bak first." -ForegroundColor DarkGray
        Write-Host ""
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

        $cur = if (Test-Path $t) { Get-Content $t -Raw -ErrorAction SilentlyContinue } else { $null }
        $written = [bool]($cur -and $cur.Trim() -eq $stub)
        for ($round = 1; $round -le 3 -and -not $written; $round++) {
            for ($i = 0; $i -lt 4 -and -not $written; $i++) {
                try { Set-Content -Path $t -Value $stub -Encoding UTF8 -ErrorAction Stop; $written = $true }
                catch { Start-Sleep -Seconds 1 }
            }
            if ($written) { break }
            Write-Host ""
            Write-Host "Fail profile sedang dikunci:" -ForegroundColor Red
            Write-Host "  $t" -ForegroundColor DarkYellow
            $lockers = @(Get-FileLockers $t)
            if ($lockers.Count -gt 0) {
                Write-Host "Proses yang guna fail ni:" -ForegroundColor Yellow
                foreach ($l in $lockers) { Write-Host "  - $l" -ForegroundColor Yellow }
                Write-Host "Tutup program tu dulu." -ForegroundColor Yellow
            } else {
                Write-Host "Tak dapat kesan proses. Biasanya OneDrive tengah sync, atau VSC/tab PowerShell lain buka fail ni." -ForegroundColor Yellow
            }
            $ans = Read-Host "Tekan Enter untuk cuba lagi (N untuk batal)"
            if ($ans -match '^[Nn]') { break }
        }
        if (-not $written) { throw "Fail profile masih dikunci. Tutup program yang guna fail ni, lepas tu run semula. Fail: $t" }
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
        Write-Host "Love you all! - Yolo" -ForegroundColor Magenta
    }
    Write-Host ""

    $choice = "2"

    # option 2 is run below, outside the function, so it loads into the current session
    $global:PSRoutesChoice = $choice
    $global:PSRoutesMain   = $main

    Write-Host ""
    Write-Host "Done." -ForegroundColor Cyan
}

$global:PSRoutesFailed = $false
try { Install-PSRoutes } catch {
    $global:PSRoutesFailed = $true
    Write-Host ""
    Write-Host "INSTALL GAGAL: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host $_.InvocationInfo.PositionMessage -ForegroundColor DarkYellow
    Write-Host "Screenshot error ni dan hantar kat Yolo." -ForegroundColor Yellow
}

if ($global:PSRoutesChoice -eq "2" -and -not $global:PSRoutesFailed) { . $global:PSRoutesMain; list }
Remove-Variable PSRoutesChoice, PSRoutesMain, PSRoutesFailed -Scope Global -ErrorAction SilentlyContinue
