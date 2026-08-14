<#
.SYNOPSIS
    Updates the author of a specific Git commit.
.DESCRIPTION
    This function allows you to change the author of a specific Git commit by providing the commit hash. It creates a temporary branch, amends the commit with the new author information, and then rebases the changes back to the original branch. Finally, it deletes the temporary branch.
.PARAMETER CommitHash
    The hash of the commit you want to change the author for.
.EXAMPLE
    Update-GitCommitAuthorship -CommitHash "abc1234"
    This command will change the author of the commit with hash "abc1234" to the specified author name and email in the script.
.NOTES
    Ensure you have the necessary permissions to modify the commit history.
#>
function Update-GitCommitAuthorship {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]
        $CommitHash,
        [Parameter(Mandatory=$false)]
        [string]
        $AuthorName = "thekovic",
        [Parameter(Mandatory=$false)]
        [string]
        $AuthorEmail = "fosskovic@gmail.com"
    )

    # Set local Git config to correct name & email in case I forgot
    git config user.name $AuthorName
    git config user.email $AuthorEmail

    $originalBranch = git rev-parse --abbrev-ref HEAD
    Write-Host "On branch $originalBranch" -ForegroundColor Cyan

    git checkout -b author-fix $CommitHash

    git commit --amend --no-edit --author="$AuthorName <$AuthorEmail>"
    Write-Host "Authorship set successfully." -ForegroundColor Cyan

    git rebase --onto author-fix $CommitHash $originalBranch
    Write-Host "Authorship change merged back to $originalBranch." -ForegroundColor Cyan

    git branch -d author-fix

    Write-Host "Don't forget to `"git push --force`" when you're done!" -ForegroundColor Yellow
}

Export-ModuleMember -Function Update-GitCommitAuthorship
