# Windows version of bin/t3-settings pull: apply .t3/shared-settings.json from these
# dotfiles to this machine's T3 Code settings. Each write backs up the target first.
# Run: powershell -ExecutionPolicy Bypass -File bin\t3-settings.ps1
param([string]$UserData = (Join-Path $env:USERPROFILE ".t3\userdata"))
$ErrorActionPreference = "Stop"

$shared = Get-Content (Join-Path $PSScriptRoot "..\.t3\shared-settings.json") -Raw | ConvertFrom-Json
$stamp = "bak-$(Get-Date -Format yyyy-MM-dd)-settings-sync"

function Apply-Section([string]$Section, [string]$File) {
  if (-not (Test-Path $File)) { Write-Host "skip ${Section}: no $File"; return }
  Copy-Item $File "$File.$stamp"
  $document = Get-Content $File -Raw | ConvertFrom-Json
  # Older client files nest the settings under "settings".
  $target = if ($document.PSObject.Properties["settings"] -and $document.settings -is [psobject]) { $document.settings } else { $document }
  foreach ($entry in $shared.$Section.PSObject.Properties) {
    $target | Add-Member -NotePropertyName $entry.Name -NotePropertyValue $entry.Value -Force
  }
  $tmp = "$File.tmp"
  $document | ConvertTo-Json -Depth 32 | Set-Content $tmp -Encoding utf8
  Move-Item $tmp $File -Force
  Write-Host "applied $(@($shared.$Section.PSObject.Properties).Count) $Section keys to $File"
}

Apply-Section "server" (Join-Path $UserData "settings.json")
Apply-Section "client" (Join-Path $UserData "client-settings.json")
Write-Host "Restart T3 Code to load the client settings."
