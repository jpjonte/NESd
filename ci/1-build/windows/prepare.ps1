flutter pub get

choco install yq

Get-ChildItem -Path "$env:USERPROFILE\AppData\Local\Pub\Cache\git" -Directory -Filter "mp-audio-stream*" | ForEach-Object {
    Set-Location $_.FullName
    git submodule init
    git submodule update
}
