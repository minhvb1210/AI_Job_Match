$ErrorActionPreference = 'Stop'

Write-Host "Fetching latest Flutter release info..."
$releasesJson = Invoke-RestMethod -Uri "https://storage.googleapis.com/flutter_infra_release/releases/releases_windows.json"
$targetHash = $releasesJson.current_release.stable
$releaseObj = $releasesJson.releases | Where-Object { $_.hash -eq $targetHash } | Select-Object -First 1
$archiveUrl = "https://storage.googleapis.com/flutter_infra_release/releases/$($releaseObj.archive)"

Write-Host "Downloading Flutter Stable $($releaseObj.version) via curl.exe... (approx 1.2GB)"
$zipPath = "$env:TEMP\flutter.zip"

# Use native curl for faster download
curl.exe -L -o $zipPath $archiveUrl

Write-Host "Extracting to C:\src..."
if (-not (Test-Path -Path C:\src)) {
    New-Item -ItemType Directory -Path C:\src | Out-Null
}
# Expand-Archive can also be slow, we'll try tar if available
try {
    tar.exe -xf $zipPath -C C:\src
} catch {
    Expand-Archive -Path $zipPath -DestinationPath C:\src -Force
}

Write-Host "Cleaning up..."
Remove-Item -Path $zipPath -Force

Write-Host "Flutter installation complete at C:\src\flutter."
