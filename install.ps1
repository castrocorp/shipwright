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

$items = @("CLAUDE.md", "agents", "commands", "prompts", "rules", "skills", "stacks")

foreach ($item in $items) {
    $src = Join-Path $EngineDir $item
    $dest = Join-Path $ClaudeDir $item

    if (-not (Test-Path $src)) {
        Write-Host "  Skip: $item (not found in engine/)"
        continue
    }

    Backup-IfExists $dest
    New-Item -ItemType SymbolicLink -Path $dest -Target $src | Out-Null
    Write-Host "  Linked: $item -> $src"
}

# Verify critical symlinks
Write-Host ""
Write-Host "Verifying symlinks..."
$fail = $false
foreach ($item in $items) {
    $dest = Join-Path $ClaudeDir $item
    if (-not (Test-Path $dest)) {
        Write-Host "  FAIL: $dest does not exist"
        $fail = $true
    }
}
if (-not $fail) {
    Write-Host "  All symlinks verified."
}

Write-Host ""
Write-Host "Done. The following were NOT touched:"
Write-Host "  - $ClaudeDir\settings.json"
Write-Host "  - $ClaudeDir\settings.local.json"
Write-Host "  - $ClaudeDir\plugins\"
Write-Host "  - $ClaudeDir\projects\"
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. cd \path\to\your\project; then run /init-project (or copy template\project.md to .claude\project.md)"
Write-Host "  2. Fill in any {PLACEHOLDER} values in .claude\project.md"
Write-Host "  3. Connect MCP integrations: copy template\mcp.json to your project, or use /mcp in Claude Code"
