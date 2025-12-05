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
