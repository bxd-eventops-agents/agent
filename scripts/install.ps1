#Requires -RunAsAdministrator
<#
.SYNOPSIS
    BXD EventOps Agent — Windows installer bootstrap
.DESCRIPTION
    Downloads the EventOps Agent and Telegraf, then runs the self-registration install.
.EXAMPLE
    iwr -Uri "https://raw.githubusercontent.com/BxD-io/eventops-agent/main/scripts/install.ps1" -OutFile install.ps1
    .\install.ps1 --url https://api.eventops.bxd.com.br --key evpr_...
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$url,

    [Parameter(Mandatory = $true)]
    [string]$key
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$GITHUB_REPO     = "bxd-eventops-agents/agent"
$TELEGRAF_VERSION = "1.33.0"
$BASE_DIR        = "C:\ProgramData\EventOps"
$TELEGRAF_DIR    = "$BASE_DIR\telegraf"
$AGENT_DIR       = "$BASE_DIR\agent"
$AGENT_BIN       = "$AGENT_DIR\eventops-agent.exe"

function Write-Step([string]$msg) { Write-Host "  [....] $msg" -ForegroundColor Cyan }
function Write-OK([string]$msg)   { Write-Host "  [ OK ] $msg" -ForegroundColor Green }
function Write-Fail([string]$msg) { Write-Host "  [FAIL] $msg" -ForegroundColor Red; exit 1 }

Write-Host ""
Write-Host "==================================================" -ForegroundColor Blue
Write-Host "  BXD EventOps Agent — Windows Bootstrap" -ForegroundColor Blue
Write-Host "==================================================" -ForegroundColor Blue
Write-Host ""

# ── Detect architecture ───────────────────────────────────────────────────────

$arch = if ($env:PROCESSOR_ARCHITECTURE -eq "ARM64") { "arm64" } else { "amd64" }
Write-OK "Architecture: $arch"

# ── Create directories ────────────────────────────────────────────────────────

foreach ($dir in @($BASE_DIR, $AGENT_DIR, $TELEGRAF_DIR, "$BASE_DIR\logs")) {
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
}
Write-OK "Directories ready"

# ── Download EventOps Agent ───────────────────────────────────────────────────

Write-Step "Downloading EventOps Agent..."
$agentUrl = "https://github.com/$GITHUB_REPO/releases/latest/download/eventops-agent-windows-$arch.exe"
try {
    Invoke-WebRequest -Uri $agentUrl -OutFile $AGENT_BIN -UseBasicParsing
    Write-OK "Agent downloaded: $AGENT_BIN"
} catch {
    Write-Fail "Failed to download agent from $agentUrl`n$_"
}

# ── Download Telegraf ─────────────────────────────────────────────────────────

Write-Step "Downloading Telegraf $TELEGRAF_VERSION..."
$telegrafArch = if ($arch -eq "arm64") { "arm64" } else { "amd64" }
$telegrafUrl  = "https://github.com/influxdata/telegraf/releases/download/v$TELEGRAF_VERSION/telegraf-$TELEGRAF_VERSION_windows_$telegrafArch.zip"
$telegrafZip  = "$env:TEMP\telegraf.zip"
try {
    Invoke-WebRequest -Uri $telegrafUrl -OutFile $telegrafZip -UseBasicParsing
    Expand-Archive -Path $telegrafZip -DestinationPath $TELEGRAF_DIR -Force
    # Flatten: telegraf puts files inside a versioned subfolder
    $inner = Get-ChildItem -Path $TELEGRAF_DIR -Filter "telegraf.exe" -Recurse | Select-Object -First 1
    if ($inner -and $inner.DirectoryName -ne $TELEGRAF_DIR) {
        Move-Item -Path "$($inner.DirectoryName)\*" -Destination $TELEGRAF_DIR -Force
        Remove-Item -Path $inner.DirectoryName -Force -ErrorAction SilentlyContinue
    }
    Remove-Item -Path $telegrafZip -Force
    Write-OK "Telegraf ready: $TELEGRAF_DIR\telegraf.exe"
} catch {
    Write-Fail "Failed to download Telegraf from $telegrafUrl`n$_"
}

# ── Run agent install (self-registration) ────────────────────────────────────

Write-Step "Registering agent with EventOps portal..."
Write-Host ""
& $AGENT_BIN install --url $url --key $key

if ($LASTEXITCODE -ne 0) {
    Write-Fail "Agent install failed (exit $LASTEXITCODE)."
}

Write-Host ""
Write-Host "==================================================" -ForegroundColor Green
Write-Host "  Installation complete!" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Green
Write-Host "  Run: Get-Service 'EventOps Agent' | Select-Object Status" -ForegroundColor Gray
Write-Host ""
