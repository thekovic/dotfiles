#!/usr/bin/env pwsh

param (
    [string]$Path = "./example",     # Path to folder with files
    [string]$Prefix = "foo",        # Fixed prefix for new filenames
    [bool]$ForReal = $false
)

$suffixes = @(
    "E01 - The Impossible Astronaut",
    "E02 - Day of the Moon",
    "E03 - The Curse of the Black Spot",
    "E04 - The Doctor's Wife",
    "E05 - The Rebel Flesh",
    "E06 - The Almost People",
    "E07 - A Good Man Goes to War",
    "E08 - Let's Kill Hitler",
    "E09 - Night Terrors",
    "E10 - The Girl Who Waited",
    "E11 - The God Complex",
    "E12 - Closing Time",
    "E13 - The Wedding of River Song"
)

# Get all files in the folder
$files = Get-ChildItem -Path $Path -File | Sort-Object Name

# Rename files
$i = 0
foreach ($file in $files)
{
    $suffix = $suffixes[$i]
    $extension = $file.Extension
    $newName = "{0}{1}{2}" -f $Prefix, $suffix, $extension
    Write-Host "Renaming" $file.FullName "to" $newName
    if ($ForReal)
    {
        Rename-Item -Path $file.FullName -NewName $newName
    }
    $i++
}
