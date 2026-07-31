# Install script for explain-diff-skill (Hermes Agent skills)
# Usage (PowerShell):
#   irm https://raw.githubusercontent.com/CheolyongKim/explain-diff-skill/main/install.ps1 | iex
#
# Downloads the `skills/` files directly from GitHub (via the git tree API +
# raw file URLs) and writes them into the Hermes Agent skills folder.
# No archive extraction is involved, so it works even where Expand-Archive /
# tar fail. It only writes inside the Hermes skills folder.

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

# 2) Ask GitHub for the file tree (recursive) and keep only skills/ blobs.
$ApiUrl = "https://api.github.com/repos/$Repo/git/trees/$Branch`?recursive=1"
Write-Host "Resolving file tree for $Repo@$Branch ..." -ForegroundColor Cyan
try {
    $tree = Invoke-RestMethod -Uri $ApiUrl -Headers @{ 'User-Agent' = 'explain-diff-installer' }
} catch {
    Write-Error "Failed to fetch repo tree from GitHub API: $_"
    exit 1
}

$blobs = $tree.tree | Where-Object { $_.path -like "$SkillsDir/*" -and $_.type -eq 'blob' }
if ($blobs.Count -eq 0) {
    Write-Error "No files found under $SkillsDir/ in the repo tree."
    exit 1
}

# 3) Download each blob to the matching path under the Hermes skills folder.
$Copied = @()
foreach ($b in $blobs) {
    $url  = "https://raw.githubusercontent.com/$Repo/$Branch/$($b.path)"
    $dest = Join-Path $SKILLS_TARGET $b.path
    New-Item -ItemType Directory -Force -Path (Split-Path $dest) | Out-Null
    try {
        if (Get-Command curl.exe -ErrorAction SilentlyContinue) {
            & curl.exe -fsSL $url -o $dest
        } else {
            Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing
        }
    } catch {
        Write-Error "Failed to download $url : $_"
        exit 1
    }
    # Track the top-level skill folder name (skills/<skill>/...).
    $skillName = ($b.path -split '/')[1]
    if ($Copied -notcontains $skillName) { $Copied += $skillName }
}

Write-Host ''
Write-Host 'explain-diff-skill installed.' -ForegroundColor Green
Write-Host "Skills folder: $SKILLS_TARGET" -ForegroundColor Gray
$Copied | Sort-Object -Unique | ForEach-Object { Write-Host "  - $_" -ForegroundColor White }
Write-Host ''
Write-Host 'Restart Hermes Agent (or run /skills) to load the new skills.' -ForegroundColor Yellow
