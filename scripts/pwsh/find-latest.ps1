#!/usr/bin/env pwsh

<#
.SYNOPSIS
    List the 10 newest files (by creation time) in a folder tree.

.PARAMETER Path
    Root folder to scan.  Defaults to the current directory.

.EXAMPLE
    .\script.ps1 -Path "C:\Data"
#>

param(
    [string]$Path = ".",
    [int]$FileCount = 10
)

function Get-ReadableSize {
    param([long]$Bytes)

    if ($Bytes -ge 1GB) {
        return ("{0,6:N2} GB" -f ($Bytes / 1GB))
    } elseif ($Bytes -ge 1MB) {
        return ("{0,6:N2} MB" -f ($Bytes / 1MB))
    } else {
        return ("{0,6:N2} KB" -f ($Bytes / 1KB))
    }
}

$Extensions = @(".cue", ".iso", ".n64", ".v64", ".z64", ".sfc", ".smc", ".nes", ".gb", ".gbc", ".gba")
$IgnoreDirs = @("libdragon", "libdragon-kovic", "vcpkg", "tiny3d")

Get-ChildItem -LiteralPath $Path -Recurse -File |
    Where-Object {
        # Must have matching extension
        $Extensions -contains $_.Extension.ToLower() -and
        # Ensure none of its parent directories match ignore list
        -not ($_.FullName.Split('\') | Where-Object { $ignoreDirs -contains $_ })
    } |
    Sort-Object -Property CreationTime -Descending |
    Select-Object -First $FileCount |
    Format-Table @{Label="Created";Expression={$_.CreationTime}},
                 @{Label="Size";Expression={Get-ReadableSize -Bytes $_.Length}},
                 @{Label="File";Expression={Resolve-Path -Relative $_.FullName}}
