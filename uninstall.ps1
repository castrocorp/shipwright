$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$EngineDir = Join-Path $ScriptDir "engine"
$ClaudeDir = Join-Path $env:USERPROFILE ".claude"

Write-Host "Shipwright - Uninstaller (Windows)"
Write-Host "===================================="
Write-Host ""
Write-Host "Engine:  $EngineDir"
Write-Host "Target:  $ClaudeDir"
Write-Host ""

if (-not (Test-Path $ClaudeDir)) {
    Write-Host "Nothing to uninstall - $ClaudeDir does not exist."
    exit 0
}

$removed = 0
$kept = 0

function Is-EngineSymlink($path) {
    if (-not (Test-Path $path)) { return $false }
    $item = Get-Item $path -Force
    if (-not ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) { return $false }
    $target = $item.Target
    return ($target -like "*$EngineDir*")
}

# --- Remove CLAUDE.md symlink ---
$claudeMd = Join-Path $ClaudeDir "CLAUDE.md"
if (Is-EngineSymlink $claudeMd) {
    (Get-Item $claudeMd -Force).Delete()
    Write-Host "  Removed: CLAUDE.md (symlink to engine)"
    $removed++
} elseif (Test-Path $claudeMd) {
    Write-Host "  Kept:    CLAUDE.md (not a symlink - user-owned)"
    $kept++
}

# --- Remove directory symlinks ---
$dirItems = @("agents", "commands", "prompts", "skills")

foreach ($item in $dirItems) {
    $dest = Join-Path $ClaudeDir $item
    if (Is-EngineSymlink $dest) {
        (Get-Item $dest -Force).Delete()
        Write-Host "  Removed: $item/ (symlink to engine)"
        $removed++
    } elseif (Test-Path $dest) {
        Write-Host "  Kept:    $item/ (not a symlink - user-owned)"
        $kept++
    }
}

# --- Remove per-file symlinks in rules/ and stacks/ ---
$mergeItems = @("rules", "stacks")

foreach ($item in $mergeItems) {
    $destDir = Join-Path $ClaudeDir $item

    # Check if whole directory is a symlink (old install style)
    if (Test-Path $destDir) {
        $dirItem = Get-Item $destDir -Force
        if ($dirItem.Attributes -band [IO.FileAttributes]::ReparsePoint) {
            if ($dirItem.Target -like "*$EngineDir*") {
                $dirItem.Delete()
                Write-Host "  Removed: $item/ (directory symlink to engine)"
                $removed++
            }
            continue
        }
    }

    if (-not (Test-Path $destDir)) { continue }

    $engineRemoved = 0
    $userKept = 0

    foreach ($f in Get-ChildItem -Path $destDir -Filter "*.md" -ErrorAction SilentlyContinue) {
        $fi = Get-Item $f.FullName -Force
        if ($fi.Attributes -band [IO.FileAttributes]::ReparsePoint) {
            if ($fi.Target -like "*$EngineDir*") {
                $fi.Delete()
                $engineRemoved++
            } else {
                $userKept++
            }
        } else {
            $userKept++
        }
    }

    if ($userKept -eq 0 -and (Test-Path $destDir)) {
        $remaining = (Get-ChildItem $destDir -ErrorAction SilentlyContinue).Count
        if ($remaining -eq 0) {
            Remove-Item $destDir
            Write-Host "  Removed: $item/ (empty after cleanup)"
        }
        $removed++
    } else {
        Write-Host "  Cleaned: $item/ - $engineRemoved engine symlink(s) removed, $userKept user file(s) preserved"
        $removed++
    }
}

# --- Remove version markers ---
foreach ($marker in @(".shipwright-version", ".shipwright-update")) {
    $markerPath = Join-Path $ClaudeDir $marker
    if (Test-Path $markerPath) {
        Remove-Item $markerPath
        Write-Host "  Removed: $marker"
        $removed++
    }
}

Write-Host ""
Write-Host "Uninstall complete."
Write-Host "  Removed: $removed item(s)"
Write-Host "  Kept:    $kept item(s)"
Write-Host ""
Write-Host "The following were NOT touched:"
Write-Host "  - $ClaudeDir\CLAUDE.local.md"
Write-Host "  - $ClaudeDir\settings.json"
Write-Host "  - $ClaudeDir\settings.local.json"
Write-Host "  - $ClaudeDir\plugins\"
Write-Host "  - $ClaudeDir\projects\"
Write-Host "  - User-created files in rules\ and stacks\"
Write-Host ""
Write-Host "To restore backups (if any): rename *.bak files back to their original names."
