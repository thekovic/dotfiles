function Write-Path {
    [CmdletBinding()]
    param()

    $env:Path -split ';' | ForEach-Object {
        if ($_ -ne '') {
            Write-Output $_
        }
    }
}

Export-ModuleMember -Function Write-Path
