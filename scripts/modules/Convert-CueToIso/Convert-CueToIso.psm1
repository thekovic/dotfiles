<#
.SYNOPSIS
    Converts a CUE/BIN disc image to a standard ISO file.
.DESCRIPTION
    This function reads a CUE file, extracts the associated BIN file, and converts it to an ISO file. It currently supports only MODE1/2352 tracks.
.PARAMETER CueFile
    The path to the CUE file to convert.
.PARAMETER OutputIso
    The path where the resulting ISO file will be saved. If not specified, the ISO will be created in the same directory as the CUE file with the same base name.
.EXAMPLE
    Convert-CueToIso -CueFile "C:\Games\MyGame.cue"
    This command will convert "MyGame.cue" and its associated BIN file to "MyGame.iso" in the same directory.
#>
function Convert-CueToIso {
    param(
        [Parameter(Mandatory = $true)]
        [string]$CueFile,

        [string]$OutputIso
    )

    $ErrorActionPreference = 'Stop'

    # Resolve the CUE path
    $cuePath = (Resolve-Path $CueFile).Path
    $cueDir  = Split-Path $cuePath -Parent

    # Read the CUE file
    $cueLines = Get-Content -LiteralPath $cuePath

    $binFile = $null
    $trackMode = $null

    foreach ($line in $cueLines) {
        # FILE "GAME.GOG" BINARY
        if ($line -match '^\s*FILE\s+"([^"]+)"\s+BINARY\s*$') {
            $binFile = $matches[1]
            continue
        }

        # TRACK 01 MODE1/2352
        if ($line -match '^\s*TRACK\s+\d+\s+(\S+)\s*$') {
            $trackMode = $matches[1]
            break
        }
    }

    if (-not $binFile) {
        throw "No FILE ... BINARY entry found in '$CueFile'."
    }

    if (-not $trackMode) {
        throw "No TRACK entry found in '$CueFile'."
    }

    if ($trackMode -ne 'MODE1/2352') {
        throw "This script currently supports MODE1/2352 tracks only. Found: $trackMode"
    }

    # The BIN path in the CUE is relative to the CUE file
    $binPath = Join-Path $cueDir $binFile

    if (-not (Test-Path -LiteralPath $binPath -PathType Leaf)) {
        throw "BIN file not found: $binPath"
    }

    # Default output name: GAME.iso
    if (-not $OutputIso) {
        $OutputIso = Join-Path $cueDir (
            [IO.Path]::GetFileNameWithoutExtension($binPath) + '.iso'
        )
    }

    # MODE1/2352:
    #   12 bytes  - sync pattern
    #    4 bytes  - sector header
    # 2048 bytes  - user data
    #  288 bytes  - EDC/ECC/padding
    $rawSectorSize = 2352
    $isoSectorSize = 2048
    $dataOffset    = 16

    $inputStream  = $null
    $outputStream = $null

    try {
        $inputStream = [IO.File]::Open(
            $binPath,
            [IO.FileMode]::Open,
            [IO.FileAccess]::Read,
            [IO.FileShare]::Read
        )

        $outputStream = [IO.File]::Open(
            $OutputIso,
            [IO.FileMode]::Create,
            [IO.FileAccess]::Write,
            [IO.FileShare]::None
        )

        $inputLength = $inputStream.Length

        if (($inputLength % $rawSectorSize) -ne 0) {
            Write-Warning "BIN size is not an exact multiple of 2352 bytes. The final incomplete sector will be ignored."
        }

        $sectorCount = [Math]::Floor($inputLength / $rawSectorSize)

        # Buffers
        $rawSector = New-Object byte[] $rawSectorSize
        $isoSector = New-Object byte[] $isoSectorSize

        for ($sector = 0; $sector -lt $sectorCount; $sector++) {
            $bytesRead = $inputStream.Read($rawSector, 0, $rawSectorSize)

            if ($bytesRead -ne $rawSectorSize) {
                throw "Unexpected end of BIN file at sector $sector."
            }

            # Strip the 16-byte sync/header and write the 2048-byte
            # Mode 1 user-data portion.
            [Array]::Copy(
                $rawSector,
                $dataOffset,
                $isoSector,
                0,
                $isoSectorSize
            )

            $outputStream.Write($isoSector, 0, $isoSectorSize)

            if (($sector % 1000) -eq 0 -or $sector -eq ($sectorCount - 1)) {
                $percent = [Math]::Round((($sector + 1) / $sectorCount) * 100, 1)

                Write-Progress `
                    -Activity "Converting BIN to ISO" `
                    -Status "$($sector + 1) / $sectorCount sectors ($percent%)" `
                    -PercentComplete $percent
            }
        }

        Write-Progress -Activity "Converting BIN to ISO" -Completed
    }
    finally {
        if ($outputStream) {
            $outputStream.Dispose()
        }

        if ($inputStream) {
            $inputStream.Dispose()
        }
    }

    Write-Host ""
    Write-Host "Conversion complete." -ForegroundColor Green
    Write-Host "Input : $binPath"
    Write-Host "Output: $OutputIso"
    Write-Host "Sectors: $sectorCount"
    Write-Host "ISO size: $([Math]::Round((Get-Item -LiteralPath $OutputIso).Length / 1MB, 2)) MB"
}

Export-ModuleMember -Function Convert-CueToIso
