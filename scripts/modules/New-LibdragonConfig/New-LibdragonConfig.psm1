<#
.SYNOPSIS
    Creates a new c_cpp_properties.json file for Visual Studio Code with the correct settings for libdragon SDK for N64.
.DESCRIPTION
    This function generates a c_cpp_properties.json file in the specified path (default is current directory) with the appropriate configurations for the libdragon SDK for N64 development. It sets the compiler path, C and C++ standards, IntelliSense mode, include paths, and defines based on the operating system. If the -Preview switch is used, it adds a define for LIBDRAGON_PREVIEW.
.PARAMETER Path
    The path where the c_cpp_properties.json file will be created. Defaults to the current directory.
.PARAMETER Preview
    If specified, adds a define for LIBDRAGON_PREVIEW in the configuration to enable preview features.
#>
function New-LibdragonConfig {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $Path = ".",

        [Parameter()]
        [switch]
        $Preview
    )

    if ($IsWindows) {
        $osName = "windows"
        $compilerPath = '${env:N64_INST}\bin\mips64-elf-g++.exe'
    } elseif ($IsLinux) {
        $osName = "linux"
        $compilerPath = '${env:N64_INST}/bin/mips64-elf-g++'
    } else {
        throw "Unsupported OS. Please send patches to add support for your OS."
    }

    $config = [ordered]@{
        configurations = @(
            [ordered]@{
                name = "N64"
                compilerPath = $compilerPath
                cStandard = "c23"
                cppStandard = "c++23"
                intelliSenseMode = "$osName-gcc-x64"
                includePath = @(
                    '${default}'
                )
                defines = @(
                    "N64"
                    if ($Preview) {
                        "LIBDRAGON_PREVIEW=1"
                    }
                )
            }
        )
        version = 4
    }

    $vsCodePath = Join-Path -Path $Path -ChildPath ".vscode"
    if (-not (Test-Path -Path $vsCodePath)) {
        New-Item -ItemType Directory -Path $vsCodePath | Out-Null
    }
    $config | ConvertTo-Json -Depth 10 | Out-File -FilePath (Join-Path -Path $vsCodePath -ChildPath "c_cpp_properties.json") -Encoding UTF8
}

Export-ModuleMember -Function New-LibdragonConfig
