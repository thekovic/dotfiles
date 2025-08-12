function Update-GitCommitAuthorship {
    [CmdletBinding()]
    param (
        [string]
        $CommitHash
    )
    
    $authorName = "thekovic"
    $authorEmail = "72971433+thekovic@users.noreply.github.com"

    $originalBranch = git rev-parse --abbrev-ref HEAD
    Write-Host "On branch $originalBranch" -ForegroundColor Cyan

    git checkout -b author-fix $CommitHash

    git commit --amend --no-edit --author="$authorName <$authorEmail>"
    Write-Host "Authorship set successfully." -ForegroundColor Cyan

    git rebase --onto author-fix $CommitHash $originalBranch
    Write-Host "Authorship change merged back to $originalBranch." -ForegroundColor Cyan

    git branch -d author-fix

    Write-Host "Don't forget to `"git push --force`" when you're done!" -ForegroundColor Yellow
}

Export-ModuleMember -Function Update-GitCommitAuthorship
