# Install Flex (and Bison) on Windows via WinFlexBison
# Run in PowerShell: .\install-flex.ps1

$Version = "2.5.25"
$ZipName = "win_flex_bison-$Version.zip"
$Url = "https://github.com/lexxmark/winflexbison/releases/download/v$Version/$ZipName"
$DestDir = "$env:USERPROFILE\win_flex_bison"
$ZipPath = "$env:TEMP\$ZipName"

Write-Host "Downloading WinFlexBison $Version..."
try {
    Invoke-WebRequest -Uri $Url -OutFile $ZipPath -UseBasicParsing
} catch {
    Write-Host "Download failed. Try manually: $Url"
    exit 1
}

if (-not (Test-Path $DestDir)) { New-Item -ItemType Directory -Path $DestDir -Force | Out-Null }
Write-Host "Extracting to $DestDir..."
Expand-Archive -Path $ZipPath -DestinationPath $DestDir -Force

# WinFlexBison extracts to DestDir with win_flex.exe and win_bison.exe in the root
$FlexPath = Join-Path $DestDir "win_flex.exe"
if (-not (Test-Path $FlexPath)) {
    $SubDir = Get-ChildItem -Path $DestDir -Directory | Select-Object -First 1
    if ($SubDir) { $DestDir = $SubDir.FullName; $FlexPath = Join-Path $DestDir "win_flex.exe" }
}

# Create flex.cmd so "flex" works (Makefiles expect "flex")
$FlexCmd = Join-Path $DestDir "flex.cmd"
@"
@echo off
"$DestDir\win_flex.exe" %*
"@ | Set-Content -Path $FlexCmd -Encoding ASCII

Write-Host ""
Write-Host "Flex is installed at: $DestDir"
Write-Host "  win_flex.exe, win_bison.exe, flex.cmd (launcher)"
Write-Host ""
Write-Host "Add to PATH (current session):"
Write-Host "  `$env:Path = `"$DestDir;`$env:Path`""
Write-Host ""
Write-Host "To add permanently:"
Write-Host "  1. Win+R -> sysdm.cpl -> Advanced -> Environment Variables"
Write-Host "  2. Under User variables, edit Path -> New -> $DestDir"
Write-Host "  3. OK and restart the terminal."
Write-Host ""
Write-Host "Verify: flex --version"

# Add to path for this session
$env:Path = "$DestDir;$env:Path"
& (Join-Path $DestDir "win_flex.exe") --version
