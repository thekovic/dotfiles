### Structure

- **home**: Configuration files that belong to user home directory. Subdirectories correspond exactly to final directory structure. In cases when Windows directories don't fit into this structure, Linux paths have priority and correct Windows path is noted in comment.
- **misc**: Various configurations for portable applications or applications that save configuration in strange places.
- **registry**: Tweaks and hacks for Windows Registry.
- **scripts**: Collection of shell scripts.
    - **linux**: Bash scripts for Linux operating systems.
    - **modules**: Cross-platform Powershell cmdlets imported as Powershell modules. To use them, add `dotfiles/scripts/modules` to your `$env:PSModulePath`.
    - **pwsh**: Cross-platform Powershell scripts.
    - **win**: Batch files and Powershell scripts for Microsoft Windows operating systems.
