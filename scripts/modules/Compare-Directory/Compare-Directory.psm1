function Get-Hash {
    param (
        [string]$FilePath
    )
    
    try {
        $sha1 = [System.Security.Cryptography.SHA1]::Create()
        $stream = [System.IO.File]::OpenRead($FilePath)
        $hashBytes = $sha1.ComputeHash($stream)
        $stream.Close()
        return ($hashBytes | ForEach-Object { "{0:x2}" -f $_ }) -join ""
    } catch {
        Write-Warning "Error hashing ${FilePath}: $_"
        return $null
    }
}

function Get-FileHashes {
    param (
        [string]$RootDir
    )

    $fileHashes = @{}

    Get-ChildItem -Path $RootDir -Recurse -File | ForEach-Object {
        $relativePath = $_.FullName.Substring($RootDir.Length).TrimStart('\', '/')
        if ($IsWindows) {
            $relativePath = $relativePath.ToLower()
        }
        $hash = Get-Hash -FilePath $_.FullName
        if ($hash) {
            $fileHashes[$relativePath] = $hash
        }
    }

    return $fileHashes
}

function Compare-Directory {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$Dir1,

        [Parameter(Mandatory=$true)]
        [string]$Dir2
    )

    $Dir1 = Resolve-Path $Dir1
    $Dir2 = Resolve-Path $Dir2

    Write-Host "`nComparing:`n  $Dir1`n  $Dir2"

    $hashes1 = Get-FileHashes -RootDir $Dir1
    $hashes2 = Get-FileHashes -RootDir $Dir2

    $allKeys = $hashes1.Keys + $hashes2.Keys | Sort-Object -Unique

    $onlyIn1 = @()
    $onlyIn2 = @()
    $different = @()
    $same = @()

    foreach ($key in $allKeys) {
        $h1 = $hashes1[$key]
        $h2 = $hashes2[$key]

        if ($h1 -and -not $h2) {
            $onlyIn1 += $key
        } elseif ($h2 -and -not $h1) {
            $onlyIn2 += $key
        } elseif ($h1 -ne $h2) {
            $different += $key
        } else {
            $same += $key
        }
    }

    Write-Host "`n🔍 Differences found:"

    if ($onlyIn1.Count -gt 0) {
        Write-Host "`n📁 Only in $Dir1"
        $onlyIn1 | ForEach-Object { Write-Host "  $_" }
    }

    if ($onlyIn2.Count -gt 0) {
        Write-Host "`n📁 Only in $Dir2"
        $onlyIn2 | ForEach-Object { Write-Host "  $_" }
    }

    if ($different.Count -gt 0) {
        Write-Host "`n⚠️ Same path, different content:"
        $different | ForEach-Object { Write-Host "  $_" }
    }

    if (-not ($onlyIn1.Count -or $onlyIn2.Count -or $different.Count)) {
        Write-Host "`n✅ All files match!"
    }
}

Export-ModuleMember -Function Compare-Directory
