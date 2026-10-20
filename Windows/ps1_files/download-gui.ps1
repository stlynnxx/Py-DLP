#Requires -Version 5.1
<#
    dwnloaderr graphical downloader.

    Shows a single window: URL field, format dropdown, Download button.
    Then runs dwnloaderr.py and streams its output to the console.

    Called by download.bat. Can also be run directly:
        powershell -ExecutionPolicy Bypass -File download-gui.ps1
#>
[CmdletBinding()]
param(
    [ValidateSet('mp4','mp3','flac','wav','opus')]
    [string]$DefaultFormat = 'mp3',

    [string]$Url,

    [switch]$NoPause
)

$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$ScriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$VenvPython = Join-Path $ScriptDir '.venv\Scripts\python.exe'
$MainScript = Join-Path $ScriptDir 'dwnloaderr.py'

# ------------------------------------------------------------- sanity checks
if (-not (Test-Path $VenvPython)) {
    Write-Host ''
    Write-Host '  The virtual environment is missing.' -ForegroundColor Red
    Write-Host ''
    Write-Host '  Run setup.bat first, then try again.'
    Write-Host ''
    if (-not $NoPause) { Read-Host '  Press Enter to close' }
    exit 1
}

if (-not (Test-Path $MainScript)) {
    Write-Host ''
    Write-Host "  Could not find dwnloaderr.py next to this script." -ForegroundColor Red
    Write-Host "  Expected: $MainScript"
    Write-Host ''
    if (-not $NoPause) { Read-Host '  Press Enter to close' }
    exit 1
}

# ------------------------------------------------------------------- dialog
function Show-InputDialog {
    param([string]$PresetUrl, [string]$PresetFormat)

    $form                 = New-Object System.Windows.Forms.Form
    $form.Text            = 'dwnloaderr Download'
    $form.Size            = New-Object System.Drawing.Size(600, 250)
    $form.StartPosition   = 'CenterScreen'
    $form.FormBorderStyle = 'FixedDialog'
    $form.MaximizeBox     = $false
    $form.MinimizeBox     = $false
    $form.Font            = New-Object System.Drawing.Font('Segoe UI', 10)

    $lblUrl           = New-Object System.Windows.Forms.Label
    $lblUrl.Text      = 'Video or playlist URL:'
    $lblUrl.Location  = New-Object System.Drawing.Point(20, 20)
    $lblUrl.Size      = New-Object System.Drawing.Size(540, 22)
    $form.Controls.Add($lblUrl)

    $txtUrl           = New-Object System.Windows.Forms.TextBox
    $txtUrl.Location  = New-Object System.Drawing.Point(20, 46)
    $txtUrl.Size      = New-Object System.Drawing.Size(545, 28)
    $txtUrl.Text      = $PresetUrl
    $form.Controls.Add($txtUrl)

    $lblHint          = New-Object System.Windows.Forms.Label
    $lblHint.Text     = 'Paste the link, then press Ctrl+V or right-click and choose Paste.'
    $lblHint.Location = New-Object System.Drawing.Point(20, 74)
    $lblHint.Size     = New-Object System.Drawing.Size(545, 20)
    $lblHint.ForeColor = [System.Drawing.Color]::Gray
    $form.Controls.Add($lblHint)

    $lblFmt           = New-Object System.Windows.Forms.Label
    $lblFmt.Text      = 'Format:'
    $lblFmt.Location  = New-Object System.Drawing.Point(20, 108)
    $lblFmt.Size      = New-Object System.Drawing.Size(120, 22)
    $form.Controls.Add($lblFmt)

    $cmb              = New-Object System.Windows.Forms.ComboBox
    $cmb.Location     = New-Object System.Drawing.Point(140, 105)
    $cmb.Size         = New-Object System.Drawing.Size(425, 28)
    $cmb.DropDownStyle = 'DropDownList'
    [void]$cmb.Items.Add('mp4  -  video, best quality')
    [void]$cmb.Items.Add('mp3  -  audio, plays anywhere')
    [void]$cmb.Items.Add('flac -  audio, lossless')
    [void]$cmb.Items.Add('wav  -  audio, uncompressed')
    [void]$cmb.Items.Add('opus -  audio, smallest file')

    $order = @('mp4','mp3','flac','wav','opus')
    $idx = [Array]::IndexOf($order, $PresetFormat.ToLower())
    if ($idx -lt 0) { $idx = 1 }
    $cmb.SelectedIndex = $idx
    $form.Controls.Add($cmb)

    $btnOk            = New-Object System.Windows.Forms.Button
    $btnOk.Text       = 'Download'
    $btnOk.Location   = New-Object System.Drawing.Point(340, 160)
    $btnOk.Size       = New-Object System.Drawing.Size(110, 34)
    $btnOk.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form.Controls.Add($btnOk)

    $btnCancel        = New-Object System.Windows.Forms.Button
    $btnCancel.Text   = 'Cancel'
    $btnCancel.Location = New-Object System.Drawing.Point(455, 160)
    $btnCancel.Size   = New-Object System.Drawing.Size(110, 34)
    $btnCancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $form.Controls.Add($btnCancel)

    $form.AcceptButton = $btnOk
    $form.CancelButton = $btnCancel
    $form.Topmost      = $true

    $txtUrl.Select()

    $result = $form.ShowDialog()
    if ($result -ne [System.Windows.Forms.DialogResult]::OK) {
        return $null
    }

    $chosen = $order[$cmb.SelectedIndex]

    return [PSCustomObject]@{
        Url    = $txtUrl.Text.Trim()
        Format = $chosen
    }
}

# --------------------------------------------------------------------- main
$selection = $null

if ($Url) {
    $selection = [PSCustomObject]@{ Url = $Url; Format = $DefaultFormat }
} else {
    $selection = Show-InputDialog -PresetUrl '' -PresetFormat $DefaultFormat
}

if (-not $selection) {
    Write-Host ''
    Write-Host '  Cancelled.' -ForegroundColor Yellow
    Write-Host ''
    if (-not $NoPause) { Read-Host '  Press Enter to close' }
    exit 0
}

if ([string]::IsNullOrWhiteSpace($selection.Url)) {
    Write-Host ''
    Write-Host '  No URL entered.' -ForegroundColor Red
    Write-Host ''
    if (-not $NoPause) { Read-Host '  Press Enter to close' }
    exit 1
}

# ------------------------------------------------------------------ download
Write-Host ''
Write-Host '  ====================================' -ForegroundColor Cyan
Write-Host '    dwnloaderr Download' -ForegroundColor Cyan
Write-Host '  ====================================' -ForegroundColor Cyan
Write-Host ''
Write-Host "  URL:    $($selection.Url)"
Write-Host "  Format: $($selection.Format)"
Write-Host ''
Write-Host '  ------------------------------------' -ForegroundColor DarkGray
Write-Host ''

# Passing values as an array avoids any shell interpretation of & or ? in URLs
$argList = @($MainScript, '-single', $selection.Url, '-format', $selection.Format)
& $VenvPython @argList
$rc = $LASTEXITCODE

Write-Host ''
Write-Host '  ------------------------------------' -ForegroundColor DarkGray
Write-Host ''

if ($rc -eq 0) {
    Write-Host '  Finished. Files are in your Downloads folder.' -ForegroundColor Green
    Write-Host "  $env:USERPROFILE\Downloads"
} else {
    Write-Host "  Download failed (exit code $rc)." -ForegroundColor Red
    Write-Host ''
    Write-Host '  Common fixes:' -ForegroundColor Yellow
    Write-Host '    - Update yt-dlp:   .venv\Scripts\python.exe -m pip install -U yt-dlp'
    Write-Host '    - Check the URL is complete and copied in full'
    Write-Host '    - Run setup.bat again if Node.js or FFmpeg are missing'
}

Write-Host ''
if (-not $NoPause) { Read-Host '  Press Enter to close' }

exit $rc