function Invoke-GitRebase {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$BaseBranch,

        [Parameter(Mandatory)]
        [string]$PrBranch
    )

    git checkout $BaseBranch
    if ($LASTEXITCODE -ne 0) { throw "Failed to checkout '$BaseBranch'." }

    git fetch origin
    if ($LASTEXITCODE -ne 0) { throw "Failed to fetch from origin." }

    git pull
    if ($LASTEXITCODE -ne 0) { throw "Failed to pull latest changes." }

    git checkout $PrBranch
    if ($LASTEXITCODE -ne 0) { throw "Failed to checkout '$PrBranch'." }

    git rebase $BaseBranch
    if ($LASTEXITCODE -ne 0) { throw "Rebase onto '$BaseBranch' failed." }

    Write-Output "Rebase completed successfully!"
}

Export-ModuleMember -Function Invoke-GitRebase
