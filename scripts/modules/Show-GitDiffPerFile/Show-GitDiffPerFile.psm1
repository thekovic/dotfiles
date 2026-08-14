<#
.SYNOPSIS
    Displays the git diff for each file in the current repository.
.DESCRIPTION
    This function iterates through each file that has changes in the current Git repository and displays the diff for that file. After displaying the diff for each file, it prompts the user to press Enter to continue to the next file. This is useful for reviewing changes in a controlled manner.
#>
function Show-GitDiffPerFile {
    git diff --name-only | ForEach-Object {
        git diff -- $_
        Read-Host "Press Enter to continue"
    }
}

Export-ModuleMember -Function Show-GitDiffPerFile
