# Windows: $HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1
# Linux:   ~/.config/powershell/Microsoft.PowerShell_profile.ps1

####################
# SECTION: Tiny utilities and functions.
####################
function Update-GitSubmodules {
    Write-Host "Updating git submodules..."
    git submodule update --init --recursive
}

function Build-Libdragon {
    [CmdletBinding()]
    param (
        [Parameter()]
        [switch]
        $Clean
    )

    if ($Clean) {
        $cmd = "make clobber"
        Invoke-Bash $cmd
    }

    $cores = $env:NUMBER_OF_PROCESSORS / 2
    $cmd = "make -j$cores install && make -j$cores tools-install && make -j$cores examples"
    Invoke-Bash $cmd
}

####################
# SECTION: Aliases.
####################
# Windows has no 'grep' so make an alias.
# Keep it on Linux too for consistent behaviour (might change my mind later).
Set-Alias grep Select-String
# Alias my own modules for easier access.
Set-Alias Invoke-Rebase Invoke-GitRebase
Set-Alias Trim-Video Edit-VideoTrim
Set-Alias Take-Commit Update-GitCommitAuthorship
Set-Alias gsmu Update-GitSubmodules

####################
# SECTION: Windows only.
####################
if ($IsWindows) {
    Set-Alias msys Invoke-Bash

    # Shadow the fake Python utility that opens Microsoft Store with Python Launcher from Winget
    function Invoke-PythonLauncher {
        py @args
    }

    Set-Alias python Invoke-PythonLauncher
}

####################
# SECTION: Linux only.
####################
if ($IsLinux) {
    # Make sure we have proper controls in the shell.
    Set-PSReadLineOption -EditMode Windows
    # Alias Microsoft Edit to 'edit' to match Windows.
    Set-Alias edit msedit
    # FEDORA ONLY: Make cmdlet to query package upgrades (because Discover won't tell me).
    function Get-Upgrades { dnf upgrade --refresh --assumeno }
    # Modify PATH based on custom '~/.path' file because Fedora is incapable of PATH edits from 'environment.d'.
    $pathFile = Join-Path $HOME ".path"
    if (Test-Path $pathFile) {
        $currentPath = $env:PATH -split ":"

        Get-Content $pathFile | ForEach-Object {
            $line = $_.Trim()
            # Skip empty lines and comments.
            if (-not $line -or $line.StartsWith("#")) {
                return
            }
            # Expand '~' to home directory.
            if ($line.StartsWith("~")) {
                $line = Join-Path $HOME $line.Substring(1)
            }
            # Append to PATH list.
            $currentPath += $line
        }

        $env:PATH = ($currentPath -join ":")
    }
}


####################
# SECTION: Autorun.
####################
Invoke-Expression (&starship init powershell)
# Fastfetch has Windows port but I somehow kinda don't feel the need on Windows.
if ($IsLinux) {
    Invoke-Expression fastfetch
}
