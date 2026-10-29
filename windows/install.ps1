#requires -Version 7.0
[CmdletBinding()]
param(
    [string]$HomeDirectory = $env:USERPROFILE,
    [string]$ProfilePath = $PROFILE
)

$ErrorActionPreference = 'Stop'
$repository = Split-Path $PSScriptRoot -Parent
$backupStamp = Get-Date -Format 'yyyyMMdd-HHmmss-fffffff'
$developerMode = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock' -ErrorAction SilentlyContinue).AllowDevelopmentWithoutDevLicense
$useLinks = $developerMode -eq 1

function Install-Entry([string]$Source, [string]$Destination) {
    $sourceItem = Get-Item -LiteralPath $Source
    New-Item -ItemType Directory -Path (Split-Path $Destination -Parent) -Force | Out-Null
    $existing = Get-Item -LiteralPath $Destination -Force -ErrorAction SilentlyContinue
    if ($existing -and $existing.LinkType) {
        if ($existing.LinkType -eq 'SymbolicLink' -and $existing.Target -eq $sourceItem.FullName) { return }
        throw "Refuse to replace a different link: $Destination"
    }
    if ($existing -and -not $sourceItem.PSIsContainer -and -not $useLinks) {
        if ((Get-FileHash -LiteralPath $Source).Hash -eq (Get-FileHash -LiteralPath $Destination).Hash) { return }
    }
    if ($existing -and $sourceItem.PSIsContainer -and -not $useLinks) {
        $sourceFiles = @(Get-ChildItem -LiteralPath $Source -File -Recurse -Force)
        $destinationFiles = @(Get-ChildItem -LiteralPath $Destination -File -Recurse -Force)
        $same = $sourceFiles.Count -eq $destinationFiles.Count
        foreach ($file in $sourceFiles) {
            $target = Join-Path $Destination ([IO.Path]::GetRelativePath($Source, $file.FullName))
            if (-not (Test-Path -LiteralPath $target -PathType Leaf)) { $same = $false; break }
            if ((Get-FileHash -LiteralPath $file.FullName).Hash -ne (Get-FileHash -LiteralPath $target).Hash) { $same = $false; break }
        }
        if ($same) { return }
    }
    if ($existing) { Move-Item -LiteralPath $Destination -Destination "$Destination.backup-$backupStamp" }
    if ($useLinks) {
        New-Item -ItemType SymbolicLink -Path $Destination -Target $sourceItem.FullName | Out-Null
    } else {
        Copy-Item -LiteralPath $Source -Destination $Destination -Recurse
    }
    Write-Host "Installed $Destination"
}

function Write-Configuration([string]$Path, [string]$Content) {
    if ((Test-Path -LiteralPath $Path) -and (Get-Content -LiteralPath $Path -Raw) -eq $Content) { return }
    New-Item -ItemType Directory -Path (Split-Path $Path -Parent) -Force | Out-Null
    if (Test-Path -LiteralPath $Path) { Copy-Item -LiteralPath $Path -Destination "$Path.backup-$backupStamp" }
    [IO.File]::WriteAllText($Path, $Content, [Text.UTF8Encoding]::new($false))
}

$claudeHome = Join-Path $HomeDirectory '.claude'
foreach ($name in @('CLAUDE.md', 'keybindings.json')) {
    Install-Entry "$repository\.claude\$name" "$claudeHome\$name"
}
foreach ($skill in Get-ChildItem "$repository\.claude\skills" -Directory) {
    Install-Entry $skill.FullName "$claudeHome\skills\$($skill.Name)"
}
$settingsPath = Join-Path $claudeHome 'settings.json'
$settings = if (Test-Path $settingsPath) { Get-Content $settingsPath -Raw | ConvertFrom-Json -AsHashtable } else { @{} }
$sourceSettings = Join-Path $repository '.claude\settings.json'
if (Test-Path $sourceSettings) {
    $sharedSettings = Get-Content $sourceSettings -Raw | ConvertFrom-Json -AsHashtable
    foreach ($key in $sharedSettings.Keys) { $settings[$key] = $sharedSettings[$key] }
}
if (-not $settings.ContainsKey('env')) { $settings['env'] = @{} }
$bashPath = Join-Path $env:ProgramFiles 'Git\bin\bash.exe'
if (-not (Test-Path $bashPath)) { throw 'Install Git for Windows first.' }
$settings['env']['CLAUDE_CODE_GIT_BASH_PATH'] = $bashPath
Write-Configuration $settingsPath (($settings | ConvertTo-Json -Depth 50) + "`n")

$codexHome = Join-Path $HomeDirectory '.codex'
Install-Entry "$repository\.claude\CLAUDE.md" "$codexHome\AGENTS.md"
$portable = [ordered]@{}
foreach ($line in Get-Content "$repository\.config\codex\config.toml") {
    if ($line.TrimStart().StartsWith('[')) { break }
    $key = $line.Split('=', 2)[0].Trim()
    if ($key -in @('model', 'model_reasoning_effort')) { $portable[$key] = $line }
}
$instructionPath = "$codexHome\AGENTS.md".Replace('\', '/')
$portable['model_instructions_file'] = 'model_instructions_file = "' + $instructionPath + '"'
$configPath = Join-Path $codexHome 'config.toml'
$configLines = if (Test-Path $configPath) { @(Get-Content $configPath) } else { @() }
$sectionStarted = $false
$updatedLines = [Collections.Generic.List[string]]::new()
foreach ($line in $configLines) {
    if (-not $sectionStarted -and $line.TrimStart().StartsWith('[')) {
        foreach ($value in $portable.Values) { $updatedLines.Add($value) }
        $sectionStarted = $true
    }
    $key = $line.Split('=', 2)[0].Trim()
    if ($sectionStarted -or -not $portable.Contains($key)) { $updatedLines.Add($line) }
}
if (-not $sectionStarted) { foreach ($value in $portable.Values) { $updatedLines.Add($value) } }
Write-Configuration $configPath (($updatedLines -join "`n").TrimEnd() + "`n")

$gitKeys = @(
    'filter.lfs.clean', 'filter.lfs.smudge', 'filter.lfs.process', 'filter.lfs.required',
    'core.fsmonitor', 'core.untrackedCache', 'core.preloadIndex', 'pack.threads',
    'feature.manyFiles', 'fetch.writeCommitGraph', 'gc.writeCommitGraph', 'index.version'
)
foreach ($key in $gitKeys) {
    $value = git config --file "$repository\.gitconfig" --get $key
    if ($LASTEXITCODE -eq 0) {
        git config --global $key $value
        if ($LASTEXITCODE -ne 0) { throw "Could not set Git option: $key" }
    }
}
foreach ($hook in Get-ChildItem "$PSScriptRoot\hooks" -File) {
    Install-Entry $hook.FullName "$HomeDirectory\.config\git\hooks\$($hook.Name)"
}
$gitSettings = [ordered]@{
    'user.name' = 'Yarden Zamir'
    'user.email' = 'dev@yarden-zamir.com'
    'core.autocrlf' = 'input'
    'init.defaultBranch' = 'main'
    'core.hooksPath' = "$HomeDirectory/.config/git/hooks".Replace('\', '/')
    'core.excludesfile' = "$repository/global.gitignore".Replace('\', '/')
    'dotfiles.windowsSymlinks' = $useLinks.ToString().ToLowerInvariant()
    'dotfiles.root' = $repository.Replace('\', '/')
}
foreach ($key in $gitSettings.Keys) {
    git config --global $key $gitSettings[$key]
    if ($LASTEXITCODE -ne 0) { throw "Could not set Git option: $key" }
}
Install-Entry "$PSScriptRoot\profile.ps1" $ProfilePath
Write-Host "Complete. Developer Mode: $useLinks. Open a new PowerShell terminal."
