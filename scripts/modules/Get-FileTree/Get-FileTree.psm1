<#
.SYNOPSIS
    Get the file tree of a directory and its subdirectories.
.DESCRIPTION
    This module provides functions to retrieve the file tree of a specified directory and its subdirectories, returning the structure as a nested object.
.PARAMETER Directory
    The root directory to scan for files and subdirectories.
.EXAMPLE
    Get-FileTree -Directory "C:\Data"
    This command will return the file tree of the "C:\Data" directory and its subdirectories.
#>
function Get-FileTree {
    param(
        [Parameter(Mandatory)]
        [string]$Directory
    )

    $children = @(
        Get-ChildItem -LiteralPath $Directory -Force |
            Sort-Object @{ Expression = { $_.PSIsContainer }; Descending = $true }, Name
    )

    $result = @()

    foreach ($child in $children) {
        if ($child.PSIsContainer) {
            $result += [ordered]@{
                name     = $child.Name
                type     = "directory"
                children = @(Get-FileTree -Directory $child.FullName)
            }
        }
        else {
            $result += [ordered]@{
                name = $child.Name
                type = "file"
            }
        }
    }

    return $result
}

<#
.SYNOPSIS
    Exports the file tree of a directory to a JSON file.
.DESCRIPTION
    This function retrieves the file tree of a specified directory and exports it to a JSON file.
.PARAMETER Path
    The root directory to scan for files and subdirectories.
.PARAMETER Output
    The path where the resulting JSON file will be saved.
.EXAMPLE
    Export-FileTree -Path "C:\Data" -Output "C:\Data\FileTree.json"
    This command will export the file tree of the "C:\Data" directory to "C:\Data\FileTree.json".
#>
function Export-FileTree {
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [string]$Output
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        throw "The specified path '$Path' does not exist or is not a directory."
    }

    # If Output is not specified, create a default output file in the current directory
    if (-not $Output) {
        $Output = Join-Path -Path (Get-Location) -ChildPath "filetree.json"
    }

    Get-FileTree -Directory $Path |
    ConvertTo-Json -Depth 100 |
    Set-Content -Path $Output -Encoding UTF8
}

Export-ModuleMember -Function Get-FileTree, Export-FileTree
