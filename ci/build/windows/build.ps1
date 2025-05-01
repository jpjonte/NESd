flutter build windows --release

$lz4library = ".\windows\eslz4-win64.dll"
$buildDirectory = ".\build\windows\x64\runner\Release\eslz4-wind64.dll"

if (-not (Test-Path -Path $buildDirectory)) {
    New-Item -ItemType Directory -Path $buildDirectory -Force
}

if (Test-Path $lz4library) {
    Copy-Item -Path $lz4library -Destination $buildDirectory
} else {
    Write-Host "File does not exist: $lz4library"
}
