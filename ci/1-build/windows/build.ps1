flutter build windows --release

$lz4library = ".\windows\eslz4-win64.dll"
$buildDirectory = ".\build\windows\x64\runner\Release"

New-Item -ItemType Directory -Path $buildDirectory -Force

if (Test-Path $lz4library) {
    Copy-Item -Path $lz4library -Destination $buildDirectory
} else {
    Write-Host "File does not exist: $lz4library"
}

New-Item -ItemType Directory -Path ".\dist" -Force

$artifactPath = Join-Path -Path ".\dist" -ChildPath "$env:ARTIFACT.windows-x64"

New-Item -ItemType Directory -Path $artifactPath -Force

Get-ChildItem $buildDirectory | Copy-Item -Destination $artifactPath -Recurse
