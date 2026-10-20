#Requires -Version 5.1
<#
    dwnloaderr Setup for Windows
    ------------------------
    Installs Python, Node.js, and FFmpeg via winget, then creates a
    virtual environment and installs yt-dlp.

    Run by double-clicking setup.bat, or:
        powershell -ExecutionPolicy Bypass -File setup.ps1

    Options:
        -SkipSystem   Only rebuild the venv and yt-dlp
        -Check        Report what is installed; change nothing
#>
[CmdletBinding()]
param(
    [switch]$SkipSystem,
    [switch]$Check
)

$ErrorActionPreference = 'Stop'

$ScriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$VenvDir    = Join-Path $ScriptDir '.venv'
$VenvPython = Join-Path $VenvDir 'Scripts\python.exe'

# ---------------------------------------------------------------- output helpers
function Write-Step { param([string]$m) Write-Host "==> $m" -ForegroundColor Cyan }
function Write-Ok   { param([string]$m) Write-Host "  [ok] $m" -ForegroundColor Green }
function Write-Warn { param([string]$m) Write-Host "  [!!] $m" -ForegroundColor Yellow }
function Write-Fail { param([string]$m) Write-Host "  [xx] $m" -ForegroundColor Red }

function Fail {
    param([string]$Message)
    Write-Fail $Message
    exit 1
}

# --------------------------------------------------------------- path refresh
function Update-SessionPath {
    $machine = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $user    = [Environment]::GetEnvironmentVariable('Path', 'User')
    $env:Path = (@($machine, $user) | Where-Object { $_ }) -join ';'
}

function Test-Tool {
    param([string]$Name)
    return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

# ---------------------------------------------------------------- winget helper
function Install-ViaWinget {
    param(
        [Parameter(Mandatory)][string]$Id,
        [Parameter(Mandatory)][string]$Label
    )

    Write-Step "Installing $Label..."

    $args = @(
        'install', '--id', $Id, '-e',
        '--silent',
        '--disable-interactivity',
        '--accept-source-agreements',
        '--accept-package-agreements'
    )

    & winget @args
    $rc = $LASTEXITCODE

    if ($rc -ne 0) {
        Write-Warn "winget returned code $rc for $Id"
        Write-Warn "Package IDs occasionally change. Try:  winget search $Label"
        return $false
    }

    Update-SessionPath
    Start-Sleep -Seconds 2
    return $true
}

# ------------------------------------------------------------------ python find
function Get-PythonExe {
    $cmd = Get-Command python -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }

    # The py launcher ships with most Python installs
    $py = Get-Command py -ErrorAction SilentlyContinue
    if ($py) {
        try {
            $found = & py -3 -c "import sys; print(sys.executable)" 2>$null
            if ($found -and (Test-Path $found)) { return $found }
        } catch { }
    }

    # Common per-user install locations
    $guesses = @(
        "$env:LOCALAPPDATA\Programs\Python\Python313\python.exe",
        "$env:LOCALAPPDATA\Programs\Python\Python312\python.exe",
        "$env:LOCALAPPDATA\Programs\Python\Python311\python.exe"
    )
    foreach ($g in $guesses) {
        if (Test-Path $g) { return $g }
    }

    return $null
}

# ==================================================================== banner
Write-Host ''
Write-Host '  dwnloaderr Setup' -ForegroundColor White
Write-Host '  ============' -ForegroundColor White
Write-Host ''

if ($Check) {
    Write-Step 'Check mode - nothing will be installed'
    Write-Host ''
}

# ============================================================== prerequisites
if (-not (Test-Tool 'winget')) {
    Write-Fail 'winget was not found.'
    Write-Host ''
    Write-Host '  winget ships with Windows 11 and Windows 10 (build 1709+).'
    Write-Host '  Update Windows, or install "App Installer" from the Microsoft Store.'
    Write-Host ''
    exit 1
}
Write-Ok 'winget available'

# ================================================================ system deps
if (-not $Check -and -not $SkipSystem) {

    # --- Python ---
    $python = Get-PythonExe
    if ($python) {
        $pyver = & $python --version 2>&1
        Write-Ok "Python present: $pyver"
    } else {
        Install-ViaWinget -Id 'Python.Python.3.12' -Label 'Python' | Out-Null
        $python = Get-PythonExe
        if (-not $python) {
            Fail 'Python still not found after install. Reboot, or install manually from python.org'
        }
        Write-Ok "Python installed: $(& $python --version 2>&1)"
    }

    # --- Node.js ---
    if (Test-Tool 'node') {
        Write-Ok "Node.js present: $(node --version)"
    } else {
        Install-ViaWinget -Id 'OpenJS.NodeJS.LTS' -Label 'Node.js' | Out-Null
        if (Test-Tool 'node') {
            Write-Ok "Node.js installed: $(node --version)"
        } else {
            Write-Warn 'Node.js not on PATH yet. Close and reopen this window, then re-run.'
        }
    }

    # --- FFmpeg ---
    if (Test-Tool 'ffmpeg') {
        Write-Ok 'FFmpeg present'
    } else {
        Install-ViaWinget -Id 'Gyan.FFmpeg' -Label 'FFmpeg' | Out-Null
        if (Test-Tool 'ffmpeg') {
            Write-Ok 'FFmpeg installed'
        } else {
            Write-Warn 'FFmpeg not on PATH yet. Reopen this window, then re-run setup.'
        }
    }

} elseif ($SkipSystem) {
    Write-Step 'Skipping system packages (-SkipSystem)'
}

# ============================================================ virtual env
if (-not $Check) {

    $python = Get-PythonExe
    if (-not $python) {
        Fail 'Cannot create the virtual environment without Python.'
    }

    if (Test-Path $VenvPython) {
        Write-Step "Reusing existing virtual environment"
    } else {
        if (Test-Path $VenvDir) {
            Write-Warn 'Removing incomplete virtual environment'
            Remove-Item -Recurse -Force $VenvDir
        }
        Write-Step 'Creating virtual environment...'
        & $python -m venv $VenvDir
        if (-not (Test-Path $VenvPython)) {
            Fail 'Virtual environment creation failed.'
        }
    }
    Write-Ok 'Virtual environment ready'

    Write-Step 'Installing yt-dlp...'
    & $VenvPython -m pip install --quiet --upgrade pip setuptools wheel
    & $VenvPython -m pip install --quiet --upgrade yt-dlp
    if ($LASTEXITCODE -ne 0) {
        Fail 'pip failed to install yt-dlp.'
    }
    Write-Ok 'yt-dlp installed'
}

# ================================================================== verify
Write-Host ''
Write-Step 'Verification'
Write-Host ''

if (Test-Path $VenvPython) {
    try {
        $ytver = & $VenvPython -c "import yt_dlp; print(yt_dlp.version.__version__)" 2>$null
        Write-Ok "yt-dlp $ytver"
    } catch {
        Write-Fail 'yt-dlp is not importable from the virtual environment'
    }
} else {
    Write-Fail 'Virtual environment missing'
}

$python = Get-PythonExe
if ($python) { Write-Ok "$(& $python --version 2>&1)" } else { Write-Warn 'Python not found' }

if (Test-Tool 'node')   { Write-Ok "Node.js $(node --version)" }   else { Write-Warn 'Node.js not found' }
if (Test-Tool 'ffmpeg') { Write-Ok 'FFmpeg ready' }                else { Write-Warn 'FFmpeg not found' }

Write-Host ''
if ($Check) {
    Write-Host '  Check complete.' -ForegroundColor Cyan
    exit 0
}

Write-Host '  ================================' -ForegroundColor Green
Write-Host '  Setup complete!' -ForegroundColor Green
Write-Host '  ================================' -ForegroundColor Green
Write-Host ''
Write-Host '  To download something:' -ForegroundColor Cyan
Write-Host '    Double-click  download.bat'
Write-Host ''
Write-Host '  Or use the command line:' -ForegroundColor Cyan
Write-Host '    Double-click  activate.bat'
Write-Host '    then type:    python dwnloaderr.py -single "URL" -format mp3'
Write-Host ''