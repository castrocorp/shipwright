$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$EngineDir = Join-Path $ScriptDir "engine"
$ClaudeDir = Join-Path $env:USERPROFILE ".claude"

Write-Host "Shipwright - Installer (Windows)"
Write-Host "=================================="
Write-Host ""
Write-Host "Source:  $EngineDir"
Write-Host "Target:  $ClaudeDir"
Write-Host ""

# Check Developer Mode (required for symlinks without admin)
$devMode = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" -Name AllowDevelopmentWithoutDevLicense -ErrorAction SilentlyContinue
if (-not $devMode -or $devMode.AllowDevelopmentWithoutDevLicense -ne 1) {
    Write-Warning "Developer Mode is not enabled. Symlinks may fail."
    Write-Warning "Enable at: Settings > For Developers > Developer Mode"
    Write-Warning ""
}

# Ensure .claude\ exists
if (-not (Test-Path $ClaudeDir)) {
    New-Item -ItemType Directory -Path $ClaudeDir | Out-Null
}

function Backup-IfExists($path) {
    if (Test-Path $path) {
        $item = Get-Item $path -Force
        if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
            $item.Delete()
        } else {
            Write-Host "  Backup: $path -> ${path}.bak"
            Move-Item $path "${path}.bak"
        }
    }
}

# --- Directory symlinks (engine-owned) ---
$dirItems = @("agents", "commands", "prompts", "skills")

foreach ($item in $dirItems) {
    $src = Join-Path $EngineDir $item
    $dest = Join-Path $ClaudeDir $item

    if (-not (Test-Path $src)) {
        Write-Host "  Skip: $item (not found in engine/)"
        continue
    }

    Backup-IfExists $dest
    New-Item -ItemType SymbolicLink -Path $dest -Target $src | Out-Null
    Write-Host "  Linked: $item/ -> $src"
}

# --- File symlink (CLAUDE.md) ---
$claudeMdDest = Join-Path $ClaudeDir "CLAUDE.md"
Backup-IfExists $claudeMdDest
New-Item -ItemType SymbolicLink -Path $claudeMdDest -Target (Join-Path $EngineDir "CLAUDE.md") | Out-Null
Write-Host "  Linked: CLAUDE.md -> $(Join-Path $EngineDir 'CLAUDE.md')"

# --- Per-file merge (rules/ and stacks/) ---
$mergeItems = @("rules", "stacks")

foreach ($item in $mergeItems) {
    $srcDir = Join-Path $EngineDir $item
    $destDir = Join-Path $ClaudeDir $item

    if (-not (Test-Path $srcDir)) {
        Write-Host "  Skip: $item (not found in engine/)"
        continue
    }

    # If dest is a symlink to a directory, replace with real directory
    if (Test-Path $destDir) {
        $destItem = Get-Item $destDir -Force
        if ($destItem.Attributes -band [IO.FileAttributes]::ReparsePoint) {
            $destItem.Delete()
            New-Item -ItemType Directory -Path $destDir | Out-Null
            Write-Host "  Converted: $item/ from directory symlink to per-file merge"
        }
    }

    if (-not (Test-Path $destDir)) {
        New-Item -ItemType Directory -Path $destDir | Out-Null
    }

    $engineCount = 0
    $userCount = 0

    foreach ($f in Get-ChildItem -Path $srcDir -Filter "*.md") {
        $destFile = Join-Path $destDir $f.Name

        if (Test-Path $destFile) {
            $existing = Get-Item $destFile -Force
            if ($existing.Attributes -band [IO.FileAttributes]::ReparsePoint) {
                # Existing engine symlink — update
                $existing.Delete()
                New-Item -ItemType SymbolicLink -Path $destFile -Target $f.FullName | Out-Null
                $engineCount++
            } else {
                # Real file — user-owned, skip
                $userCount++
            }
        } else {
            # New engine file — create symlink
            New-Item -ItemType SymbolicLink -Path $destFile -Target $f.FullName | Out-Null
            $engineCount++
        }
    }

    Write-Host "  Merged: $item/ - $engineCount engine file(s) symlinked, $userCount user file(s) preserved"
}

# Verify
Write-Host ""
Write-Host "Verifying installation..."
$fail = $false
$allItems = @("CLAUDE.md") + $dirItems + $mergeItems
foreach ($item in $allItems) {
    $dest = Join-Path $ClaudeDir $item
    if (-not (Test-Path $dest)) {
        Write-Host "  FAIL: $dest does not exist"
        $fail = $true
    }
}
if (-not $fail) {
    Write-Host "  All items verified."
}

# Write version marker
$versionFile = Join-Path $ScriptDir "VERSION"
if (Test-Path $versionFile) {
    $version = (Get-Content $versionFile -Raw).Trim()
} else {
    $version = "unknown"
}
$marker = Join-Path $ClaudeDir ".shipwright-version"
@"
version=$version
repo=$ScriptDir
installed=$((Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss"))
"@ | Set-Content $marker
Write-Host "  Version: $version (recorded in $marker)"

Write-Host ""
Write-Host "Done. The following were NOT touched:"
Write-Host "  - $ClaudeDir\CLAUDE.local.md (personal overrides)"
Write-Host "  - $ClaudeDir\settings.json"
Write-Host "  - $ClaudeDir\settings.local.json"
Write-Host "  - $ClaudeDir\plugins\"
Write-Host "  - $ClaudeDir\projects\"
Write-Host "  - User files in $ClaudeDir\rules\ and $ClaudeDir\stacks\"
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. cd \path\to\your\project; then run /init-project (or copy template\project.md to .claude\project.md)"
Write-Host "  2. Fill in any {PLACEHOLDER} values in .claude\project.md"
Write-Host "  3. Connect MCP integrations: copy template\mcp.json to your project, or use /mcp in Claude Code"
