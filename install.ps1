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
    # Order of preference:
    #   - $HERMES_SKILLS_DIR (explicit override)
    #   - <local data>/hermes/skills
    #   - <roaming data>/hermes/skills
    #   - ~/.hermes/skills
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
    # Default to the local-appdata location even if not present yet.
    return $candidates[0]
}

$SKILLS_TARGET = Find-HermesSkillsDir
New-Item -ItemType Directory -Force -Path $SKILLS_TARGET | Out-Null

# 2) Download a zip of the repo and extract only the skills/ folder.
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
$Extracted = Join-Path $TempDir 'extracted'
Expand-Archive -Path $ZipPath -DestinationPath $Extracted -Force
# GitHub archive root is <repo>-<branch>/
$RepoRoot = Get-ChildItem -Directory $Extracted | Select-Object -First 1
$SourceSkills = Join-Path $RepoRoot $SkillsDir

if (-not (Test-Path $SourceSkills)) {
    Write-Error "Could not find $SkillsDir/ in the downloaded archive."
    exit 1
}

# 4) Copy each skill folder into the Hermes skills dir.
$Copied = @()
Get-ChildItem -Directory $SourceSkills | ForEach-Object {
    $dst = Join-Path $SKILLS_TARGET $_.Name
    Copy-Item -Path $_.FullName -Destination $dst -Recurse -Force
    $Copied += $_.Name
}

# 5) Cleanup.
Remove-Item -Recurse -Force $TempDir

Write-Host ''
Write-Host 'explain-diff-skill installed.' -ForegroundColor Green
Write-Host "Skills folder: $SKILLS_TARGET" -ForegroundColor Gray
$Copied | ForEach-Object { Write-Host "  - $_" -ForegroundColor White }
Write-Host ''
Write-Host 'Restart Hermes Agent (or run /skills) to load the new skills.' -ForegroundColor Yellow
