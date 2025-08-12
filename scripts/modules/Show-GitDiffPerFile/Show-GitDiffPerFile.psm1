function Show-GitDiffPerFile {
    git diff --name-only | ForEach-Object {
        git diff -- $_
        Read-Host "Press Enter to continue"
    }
}