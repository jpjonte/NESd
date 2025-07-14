flutter pub get

$repoDirectory = Get-Location

Get-ChildItem -Path "$env:USERPROFILE\AppData\Local\Pub\Cache\git" -Directory -Filter "mp-audio-stream*" | ForEach-Object {
    Set-Location $_.FullName
    git submodule init
    git submodule update
}

Set-Location $repoDirectory

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
