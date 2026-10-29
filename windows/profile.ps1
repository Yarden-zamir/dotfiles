$env:DOTFILES = Join-Path $HOME 'Github\dotfiles\main'
$env:CLAUDE_CODE_GIT_BASH_PATH = Join-Path $env:ProgramFiles 'Git\bin\bash.exe'
Set-Alias -Name g -Value git
Set-Alias -Name github -Value gh

function prompt {
    $previousSuccess = $?
    $previousExitCode = $global:LASTEXITCODE
    $location = $executionContext.SessionState.Path.CurrentLocation
    $branch = if ($location.Provider.Name -eq 'FileSystem') {
        git --no-optional-locks symbolic-ref --short HEAD 2>$null
        if ($LASTEXITCODE -ne 0) { git --no-optional-locks rev-parse --short HEAD 2>$null }
    }
    $global:LASTEXITCODE = $previousExitCode
    $marker = if ($previousSuccess) { '>' } else { '!' }
    $suffix = if ($branch) { " [$branch]" } else { '' }
    "PS $location$suffix $marker "
}
