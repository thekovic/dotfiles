<#
.SYNOPSIS
    Invokes a bash shell with the given arguments.
.DESCRIPTION
    This function checks if bash is available on the system and invokes it with the provided arguments. It handles some special cases for Windows environments such as backwards slashes and environment variables.
.EXAMPLE
    Invoke-Bash make -B
.EXAMPLE
    Invoke-Bash .\build.sh
.NOTES
    This function does not handle passing through quotes or special characters in arguments. The arguments are passed as a single string to bash. It is recommended to use this function for simple command invocations and avoid passing paths with spaces.
#>
function Invoke-Bash {
    if (-not (Get-Command bash -ErrorAction SilentlyContinue)) {
        $errMessage = "'bash' was not found. Please install MSYS2 and ensure bash.exe is on PATH."
        if ($IsWindows) {
            $errMessage += " Please install MSYS2 and ensure bash.exe is on PATH."
        }
        Write-Error -Message $errMessage -ErrorAction Stop
        return
    }

    # Convert special token '§§and§§' to '&&' to allow for multiple commands in a single Invoke-Bash call.
    $convertedArgs = $args | ForEach-Object { ($_ -replace '§§and§§', '&&') }
    if ($IsWindows) {
        # Convert backwards slashes to forward slashes to handle autosuggest on Windows.
        $convertedArgs = $convertedArgs | ForEach-Object { ($_ -replace '\\', '/') }
    }
    # Surround arguments with quotes so that they're single string for bash.
    $convertedArgs = '"' + ($convertedArgs -join ' ') + '"'
    # Print what we got for debugging purpose.
    Write-Host "[bash]" $convertedArgs
    # Prepend "-c" so that bash interprets our arguments as command.
    $convertedArgs = @("-c") + @($convertedArgs)

    # On Linux, we can just spawn bash directly without extra setup.
    if (-not $IsWindows) {
        $process = Start-Process bash -NoNewWindow -PassThru -Wait -ArgumentList ($convertedArgs -join ' ')
        return $process.ExitCode
    }

    # Spawn bash instance on Windows.
    # Set MSYSTEM=UCRT64 to try to pass off as proper MSYS2 UCRT64 environment.
    # Add MSYS2 UCRT64 folders to the start of PATH so that Windows\System32 EXEs can't shadow Unix tools.
    $process = Start-Process bash -NoNewWindow -PassThru -Wait -ArgumentList ($convertedArgs -join ' ') -Environment @{
        MSYSTEM = 'UCRT64';
        PATH = '/ucrt64/bin:/usr/local/bin:/usr/bin:/bin:' + $env:Path
    }

    return $process.ExitCode
}

Export-ModuleMember -Function Invoke-Bash
