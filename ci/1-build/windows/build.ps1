$ErrorActionPreference = "Stop"

flutter pub get

if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

$repoDirectory = Get-Location
$nesdDirectory = Join-Path -Path $repoDirectory -ChildPath ".\packages\nesd"

Set-Location $nesdDirectory

flutter build windows --release

if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

Set-Location $repoDirectory

$buildDirectory = ".\packages\nesd\build\windows\x64\runner\Release"

# The LZ4 library is installed into the bundle by windows/CMakeLists.txt.
# Fail the build if it's missing.
$lz4library = Join-Path -Path $buildDirectory -ChildPath "eslz4-win64.dll"

if (-not (Test-Path $lz4library)) {
    Write-Error "LZ4 library missing from the build output: $lz4library"
}

New-Item -ItemType Directory -Path ".\dist" -Force

$artifactPath = Join-Path -Path ".\dist" -ChildPath "$env:ARTIFACT.windows-x64"

New-Item -ItemType Directory -Path $artifactPath -Force

Get-ChildItem $buildDirectory | Copy-Item -Destination $artifactPath -Recurse
