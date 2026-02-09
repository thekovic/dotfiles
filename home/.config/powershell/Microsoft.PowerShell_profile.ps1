# Windows: $HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1
# Linux:   ~/.config/powershell/Microsoft.PowerShell_profile.ps1

# Windows has no 'grep' so make an alias.
# Keep it on Linux too for consistent behaviour (might change my mind later).
Set-Alias grep Select-String
# Alias my own modules for easier access.
Set-Alias Invoke-Rebase Invoke-GitRebase
Set-Alias Trim-Video Edit-VideoTrim
Set-Alias Take-Commit Update-GitCommitAuthorship

if ($IsWindows) {
    function Invoke-Bash {
        if (-not (Get-Command bash -ErrorAction SilentlyContinue)) {
            Write-Error "'bash' was not found. Please install MSYS2 and ensure bash.exe is on PATH."
            return
        }

        $convertedArgs = $args | ForEach-Object {
            '"' + ($_ -replace '\\', '/') + '"'
        }

        Start-Process bash -NoNewWindow -Wait -ArgumentList ($convertedArgs -join ' ') -Environment @{
            MSYSTEM = 'UCRT64'
        }
    }

    Set-Alias msys Invoke-Bash
}

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

# Autorun section.
Invoke-Expression (&starship init powershell)
# Fastfetch has Windows port but I somehow kinda don't feel the need on Windows.
if ($IsLinux) {
    Invoke-Expression fastfetch
}
