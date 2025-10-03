flutter pub get

$repoDirectory = Get-Location
$nesdDirectory = Join-Path -Path $repoDirectory -ChildPath ".\packages\nesd"

Get-ChildItem -Path "$env:USERPROFILE\AppData\Local\Pub\Cache\git" -Directory -Filter "mp-audio-stream*" | ForEach-Object {
    Set-Location $_.FullName
    git submodule init
    git submodule update
}

Set-Location $nesdDirectory

flutter build windows --release

Set-Location $repoDirectory

$lz4library = ".\windows\eslz4-win64.dll"
$buildDirectory = ".\packages\nesd\build\windows\x64\runner\Release"

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
