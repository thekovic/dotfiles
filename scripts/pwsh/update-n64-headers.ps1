param (
    # Paths to directories with cloned libdragon and tiny3d repositories respectively.
    # By default, assumes they are in the parent directory to this script.
    [string]$LibdragonPath = "../libdragon",
    [string]$Tiny3dPath = "../tiny3d",
    # Output path for header files. Defaults to 'include' directory in the same directory as this script.
    [string]$OutputPath = "./include",
    # If specified, cleans existing header files in the output directory before updating.
    [switch]$Clean
)

function Copy-ItemsAndPreserveDirectoryStructure {
    param (
        [string]$SourcePath,
        [string]$DestinationPath,
        [string]$Filter
    )

    $items = Get-ChildItem -Path $SourcePath -Filter $Filter -Recurse
    # Filter out files in 'newlib_overrides' directory
    $items = $items | Where-Object { $_.FullName -notmatch 'newlib_overrides' }
    foreach ($item in $items) {
        # Remove source path prefix from full path to get target part missing in destination
        $itemPath = $item.FullName.Substring($SourcePath.Length).TrimStart('\','/')
        $targetFilePath = Join-Path $DestinationPath $itemPath
        $targetDir = Split-Path $targetFilePath -Parent

        if (-not (Test-Path $targetDir)) {
            New-Item -ItemType Directory -Path $targetDir | Out-Null
        }

        Copy-Item -Path $item.FullName -Destination $targetFilePath -Force
    }
}

function Update-LibdragonHeaders {
    param (
        [string]$LibdragonPath,
        [string]$OutputPath
    )
    
    Write-Host "Updating libdragon headers from $LibdragonPath"
    # Copy .h files preserving directory structure
    Copy-ItemsAndPreserveDirectoryStructure -SourcePath "$LibdragonPath/include" -DestinationPath $OutputPath -Filter "*.h"
    # Copy RSP ucode .inc files flatly into include directory
    Copy-Item -Path "$LibdragonPath/include/*" -Destination $OutputPath -Filter "*.inc" -Recurse -Force
}

function Update-Tiny3dHeaders {
    param (
        [string]$Tiny3dPath,
        [string]$OutputPath
    )

    Write-Host "Updating tiny3d headers from $Tiny3dPath"
    $OutputPath = Join-Path $OutputPath "t3d"
    if (-not (Test-Path $OutputPath)) {
        New-Item -ItemType Directory -Path $OutputPath | Out-Null
    }
    Copy-Item -Path "$Tiny3dPath/src/t3d/*.h" -Destination $OutputPath -Recurse -Force
}

if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath | Out-Null
}

# Optionally clean existing headers
if ($Clean) {
    Write-Host "Cleaning existing header files..."
    Remove-Item -Path $OutputPath -Recurse -Force
    New-Item -ItemType Directory -Path $OutputPath | Out-Null
}

Update-LibdragonHeaders -LibdragonPath $(Resolve-Path $LibdragonPath) $(Resolve-Path $OutputPath)
Update-Tiny3dHeaders -Tiny3dPath $(Resolve-Path $Tiny3dPath) $(Resolve-Path $OutputPath)
Write-Host "Header files updated successfully."
