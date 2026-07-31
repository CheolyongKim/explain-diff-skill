# Install script for explain-diff-skill (Hermes Agent skills)
# Usage (PowerShell):
#   irm https://raw.githubusercontent.com/CheolyongKim/explain-diff-skill/main/install.ps1 | iex
#
# This downloads the `skills/` directory from the GitHub repo and copies it
# into the Hermes Agent skills folder so the skills show up in Hermes.
# It does NOT touch anything outside the Hermes skills folder.

$ErrorActionPreference = 'Stop'

$Repo   = 'CheolyongKim/explain-diff-skill'
$Branch = 'main'
$SkillsDir = 'skills'

# 1) Locate the Hermes skills folder.
function Find-HermesSkillsDir {
    if ($env:HERMES_SKILLS_DIR -and (Test-Path $env:HERMES_SKILLS_DIR)) {
        return $env:HERMES_SKILLS_DIR
    }
    $candidates = @(
        (Join-Path $env:LOCALAPPDATA 'hermes\skills'),
        (Join-Path $env:APPDATA 'hermes\skills'),
        (Join-Path $env:USERPROFILE '.hermes\skills')
    )
    foreach ($c in $candidates) {
        if (Test-Path $c) { return $c }
    }
    return $candidates[0]
}

$SKILLS_TARGET = Find-HermesSkillsDir
New-Item -ItemType Directory -Force -Path $SKILLS_TARGET | Out-Null

# 2) Download a zip of the repo.
$TempDir = Join-Path $env:TEMP ('explain-diff-skill-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $TempDir | Out-Null
$ZipPath = Join-Path $TempDir 'repo.zip'
$Url = "https://github.com/$Repo/archive/refs/heads/$Branch.zip"

Write-Host "Downloading $Repo@$Branch ..." -ForegroundColor Cyan
try {
    if (Get-Command curl.exe -ErrorAction SilentlyContinue) {
        & curl.exe -fsSL $Url -o $ZipPath
    } else {
        Invoke-WebRequest -Uri $Url -OutFile $ZipPath -UseBasicParsing
    }
} catch {
    Write-Error "Failed to download $Url : $_"
    exit 1
}

# 3) Extract.
# Prefer tar.exe (built into Windows 10/11). PowerShell 5.1's Expand-Archive
# silently drops empty directory entries from the zip, which breaks the
# `skills/` folder layout, so we avoid it.
$Extracted = Join-Path $TempDir 'extracted'
New-Item -ItemType Directory -Force -Path $Extracted | Out-Null
if (Get-Command tar.exe -ErrorAction SilentlyContinue) {
    & tar.exe -xf $ZipPath -C $Extracted
} else {
    Expand-Archive -Path $ZipPath -DestinationPath $Extracted -Force
}

# 4) Find every SKILL.md under the extracted repo (recursive, robust to the
#    empty-directory bug). Each SKILL.md lives in <skill>/SKILL.md, so its
#    parent directory is the skill folder we want to copy.
$RepoRoot = Get-ChildItem -Directory $Extracted | Select-Object -First 1
$SkillFiles = @(Get-ChildItem -Path $RepoRoot -Recurse -Filter SKILL.md -File)

if ($SkillFiles.Count -eq 0) {
    Write-Error "Could not find any SKILL.md in the downloaded archive."
    exit 1
}

$Copied = @()
foreach ($sf in $SkillFiles) {
    $skillFolder = $sf.Directory.FullName
    $dst = Join-Path $SKILLS_TARGET $sf.Directory.Name
    Copy-Item -Path $skillFolder -Destination $dst -Recurse -Force
    $Copied += $sf.Directory.Name
}

# 5) Cleanup.
Remove-Item -Recurse -Force $TempDir

Write-Host ''
Write-Host 'explain-diff-skill installed.' -ForegroundColor Green
Write-Host "Skills folder: $SKILLS_TARGET" -ForegroundColor Gray
$Copied | Sort-Object -Unique | ForEach-Object { Write-Host "  - $_" -ForegroundColor White }
Write-Host ''
Write-Host 'Restart Hermes Agent (or run /skills) to load the new skills.' -ForegroundColor Yellow
