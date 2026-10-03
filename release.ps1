# Run this from the repo folder whenever you want to publish an update.
#   .\release.ps1                                   -> 1.0.0 -> 1.0.1  (small fix)
#   .\release.ps1 -Bump minor -Msg "Add updater"    -> 1.0.1 -> 1.1.0  (new feature)
#   .\release.ps1 -Bump major -Msg "Big rewrite"    -> 1.1.0 -> 2.0.0
param(
    [ValidateSet("patch", "minor", "major")][string]$Bump = "patch",
    [string]$Msg = "Update"
)

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

$versionFile = Join-Path $PSScriptRoot "VERSION"
$old = if (Test-Path $versionFile) { (Get-Content $versionFile -Raw).Trim() } else { "1.0.0" }
$v = [version]$old
if ($v.Build -lt 0) { $v = [version]"$($v.Major).$($v.Minor).0" }

$new = switch ($Bump) {
    "major" { "{0}.0.0" -f ($v.Major + 1) }
    "minor" { "{0}.{1}.0" -f $v.Major, ($v.Minor + 1) }
    default { "{0}.{1}.{2}" -f $v.Major, $v.Minor, ($v.Build + 1) }
}

Set-Content -Path $versionFile -Value $new -NoNewline
git add .
git commit -m "v$new - $Msg"
git tag "v$new"
git push
git push --tags

Write-Host ""
Write-Host "Released v$new (was v$old)" -ForegroundColor Green
