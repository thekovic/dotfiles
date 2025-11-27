# Windows: $HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1
# Linux:   ~/.config/powershell/Microsoft.PowerShell_profile.ps1

Set-Alias grep Select-String

Set-Alias Invoke-Rebase Invoke-GitRebase

Set-Alias Trim-Video Edit-VideoTrim

# Must be last.
Invoke-Expression (&starship init powershell)
