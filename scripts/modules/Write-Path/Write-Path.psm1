<#
.SYNOPSIS
    Displays the current PATH environment variable in a readable format.
.DESCRIPTION
    This function splits the PATH environment variable into individual paths and displays them line by line for easier reading. It automatically detects the operating system to use the correct path delimiter.
#>
function Write-Path {
    [CmdletBinding()]
    param()

    if ($IsLinux) {
        $pathDelim = ':'
    } else {
        $pathDelim = ';'
    }
    Write-Host "PATH:"
    $env:PATH -split $pathDelim | ForEach-Object {
        if ($_ -ne '') {
            Write-Output $_
        }
    }
}

Export-ModuleMember -Function Write-Path
