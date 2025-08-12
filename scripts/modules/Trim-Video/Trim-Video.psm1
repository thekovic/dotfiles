function Convert-ToSeconds {
    param([string]$Time)

    # Handle HH:MM:SS[.ms], MM:SS[.ms], or SS[.ms]
    if ($Time -match '^(\d+):([0-5]?\d):([0-5]?\d(?:\.\d+)?)$') {
        # HH:MM:SS(.ms)
        $h = [double]$matches[1]
        $m = [double]$matches[2]
        $s = [double]$matches[3]
        return ($h * 3600) + ($m * 60) + $s
    } elseif ($Time -match '^([0-5]?\d):([0-5]?\d(?:\.\d+)?)$') {
        # MM:SS(.ms)
        $m = [double]$matches[1]
        $s = [double]$matches[2]
        return ($m * 60) + $s
    } elseif ($Time -match '^\d+(?:\.\d+)?$') {
        # Seconds only.
        return [double]$Time
    } else {
        Write-Error "Invalid time format: $Time. Use [HH:]MM:SS[.ms] or seconds."
        exit 1
    }
}

function Get-VideoDuration {
    param (
        [Parameter(Mandatory = $true)]
        [string]$VideoFile
    )
    
    # Get total video duration to avoid going out of bounds.
    $durationCmd = @(
        "ffprobe",
        "-v", "error",
        "-show_entries", "format=duration",
        "-of", "default=noprint_wrappers=1:nokey=1",
        "`"$VideoFile`""
    ) -join ' '

    $duration = [double](Invoke-Expression $durationCmd)
    if (-not $duration) {
        throw "ffprobe is unable to determine duration of $VideoFile."
    }

    return $duration
}

function Get-FirstKeyframeTime {
    param (
        [Parameter(Mandatory = $true)]
        [string]$VideoFile,
        [Parameter(Mandatory = $true)]
        [double]$ScanStart,
        [Parameter(Mandatory = $true)]
        [double]$ScanEnd,
        [Parameter(Mandatory = $true)]
        [bool]$FindEarliest
    )

    $scanDuration = $ScanEnd - $ScanStart
    Write-Host "Scanning from $ScanStart to $ScanEnd ($scanDuration)"

    # Run ffprobe to get keyframe timestamps.
    $findKeyframesCmd = @(
        "ffprobe",
        "-v", "error",
        "-select_streams", "v:0",
        "-skip_frame", "nokey",
        "-show_frames",
        "-show_entries", "frame=pts_time",
        "-read_intervals", "$ScanStart%+$scanDuration",
        "-of", "csv=p=0",
        "`"$VideoFile`""
    ) -join ' '

    $keyframes = (Invoke-Expression $findKeyframesCmd)
    if ($LASTEXITCODE -ne 0 -or -not $keyframes) {
        throw "ffprobe failed or returned no output for '$VideoFile'."
    }

    # Find the nearest keyframe.
    if ($FindEarliest) {
        $keyframe = $keyframes | Where-Object { $_ -ge $ScanStart }   | Sort-Object | Select-Object -First 1
        # If there's no keyframe found after timestamp, don't trim at all.
        if (-not $keyframe) {
            $keyframe = $ScanEnd
        }
        return $keyframe
    } else {
        return $keyframes | Where-Object { $_ -le $ScanEnd } | Sort-Object -Descending | Select-Object -First 1
    }
}

function Edit-VideoTrim {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)] [string]$StartTime,
        [Parameter(Mandatory = $true)] [string]$EndTime,
        [Parameter(Mandatory = $true)] [string]$InputFile,
        [Parameter(Mandatory = $true)] [string]$OutputFile
    )
    
    Write-Host "Extracting keyframes from video..."

    # Convert start and end times to seconds.
    $startSeconds = Convert-ToSeconds $StartTime
    $endSeconds   = Convert-ToSeconds $EndTime
    $duration     = Get-VideoDuration $InputFile

    # Calculate scanning range (10s before start, 10s after end, clipped to video bounds)
    $scanStart = [Math]::Max(0, $startSeconds - 10)
    $scanEnd   = [Math]::Min($duration, $endSeconds + 10)

    $startKeyframe = Get-FirstKeyframeTime $InputFile $scanStart $startSeconds $false
    Write-Host "Nearest keyframe before $StartTime is at: $startKeyframe sec"
    $endKeyframe = Get-FirstKeyframeTime $InputFile $endSeconds $scanEnd $true
    Write-Host "Nearest keyframe before $EndTime is at: $endKeyframe sec"

    # Run ffmpeg to trim from nearest keyframe
    ffmpeg -ss $startKeyframe -to $endKeyframe -i "$InputFile" -c copy "$OutputFile"
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Error occurred while trimming the video."
        exit $LASTEXITCODE
    }

    Write-Host "Trimmed video saved as '$OutputFile'"

    $newDuration = Get-VideoDuration $OutputFile
    Write-Host "Original video duration: $duration"
    Write-Host "Target video duration: $($endKeyframe - $startKeyframe)"
    Write-Host "New video duration: $newDuration"
}

Export-ModuleMember -Function Edit-VideoTrim
