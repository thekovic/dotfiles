#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Multi-version launcher for the Ares emulator.
.DESCRIPTION
    Searches ARES_HOME for files named ares-vXXX.exe and librashader-vXXX.dll,
    where XXX is the version number. You can optionally specify the version as an argument.
    If no version is given, it automatically picks the highest available version.
.EXAMPLE
    .\launch-ares.ps1 146
.EXAMPLE
    .\launch-ares.ps1
#>

param (
    [Parameter(Position=0)]
    [string]$Game,          # Optional path to a game file to launch
    [string]$Version        # Optional version number (e.g. 146)
)

function Start-Ares {
    param (
        [string]$Game,
        [string]$Version
    )

    $exeSuffix = ($IsWindows)? ".exe" : ""
    
    # Find all ares-v*.exe files
    $aresFiles = Get-ChildItem -Filter "ares-v*$exeSuffix" -ErrorAction SilentlyContinue
    if (-not $aresFiles) {
        Write-Host "No ares-vXXX$exeSuffix files found in $aresDir." -ForegroundColor Yellow
        # Launch Ares and wait for exit
        Write-Host "Launching Ares (unknown version)..." -ForegroundColor Green
        Start-Process -FilePath ".\ares$exeSuffix" -ArgumentList $Game -Wait
        return
    }

    # Extract version numbers
    $versions = @()
    foreach ($file in $aresFiles) {
        if ($file.BaseName -match '^ares-v(\d+)$') {
            $versions += [int]$Matches[1]
        }
    }

    if (-not $versions) {
        Write-Host "No valid versioned ares executables found in $aresDir." -ForegroundColor Red
        return
    }

    # Choose version
    if (-not $Version) {
        $Version = ($versions | Sort-Object -Descending | Select-Object -First 1)
        Write-Host "No version specified. Using newest version: v$Version" -ForegroundColor Yellow
    } elseif (-not ($versions -contains [int]$Version)) {
        Write-Host "Version v$Version not found." -ForegroundColor Red
        return
    }

    # Compose filenames
    $exeFile = "ares-v$Version$exeSuffix"
    $dllFile = "librashader-v$Version.dll"

    # Verify both files exist
    if (-not (Test-Path $exeFile)) {
        Write-Host "Missing file: $exeFile" -ForegroundColor Red
        return
    }
    if (-not (Test-Path $dllFile)) {
        Write-Host "Missing file: $dllFile" -ForegroundColor Red
        return
    }

    # Backup current ares.exe and librashader.dll if they exist
    $backupExe = $null
    $backupDll = $null

    if (Test-Path "ares$exeSuffix") {
        $backupExe = "ares-backup-$([DateTime]::Now.ToString('yyyyMMddHHmmss'))$exeSuffix"
        Rename-Item "ares$exeSuffix" $backupExe
    }
    if (Test-Path "librashader.dll") {
        $backupDll = "librashader-backup-$([DateTime]::Now.ToString('yyyyMMddHHmmss')).dll"
        Rename-Item "librashader.dll" $backupDll
    }

    # Rename selected versioned files
    Rename-Item $exeFile "ares$exeSuffix"
    Rename-Item $dllFile "librashader.dll"

    try {
        # Launch Ares and wait for exit
        Write-Host "Launching Ares v$Version..." -ForegroundColor Green
        Start-Process -FilePath ".\ares$exeSuffix" -ArgumentList $Game -Wait
    }
    finally {
        # Restore file names
        Rename-Item "ares$exeSuffix" $exeFile
        Rename-Item "librashader.dll" $dllFile

        if ($backupExe) {
            Rename-Item $backupExe "ares$exeSuffix"
        }
        if ($backupDll) {
            Rename-Item $backupDll "librashader.dll"
        }

        Write-Host "Restored original files. Done." -ForegroundColor Cyan
    }
}

# Get absolute path to game
if ($Game -and (Test-Path $Game)) {
    $gamePath = (Resolve-Path $Game).Path
    # Windows apps launched from WSL still expect Windows paths.
    # Convert path to Windows path if launching from WSL
    if (($null -ne $env:WSL_DISTRO_NAME) -and $IsLinux) {
        $gamePath = wslpath -w $gamePath
    }
} else {
    $gamePath = ''
}

# Get ares directory from environment
$aresDir = $env:ARES_HOME
if (-not $aresDir) {
    # Last ditch attempt - try the script directory itself
    $aresDir = Split-Path -Parent $MyInvocation.MyCommand.Path
}

# Ensure we are in the script directory
Push-Location -Path $aresDir

Start-Ares $gamePath $Version

Pop-Location
