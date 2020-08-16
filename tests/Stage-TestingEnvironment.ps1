New-Item -ItemType directory "C:\Program Files\Guild Wars 2\bin64"
Write-Output "" >> "C:\Program Files\Guild Wars 2\GW2-64.exe"

$ErrorActionPreference = "Stop"
Try {
    &powershell.exe ../Bootstrap-ArcDPS.ps1
} Finally {
    Remove-Item -Recurse -Path "C:\Program Files\Guild Wars 2" -EA 0
    Remove-Item -Recurse -Path $(Join-Path "$env:APPDATA" "Update-ArcDPS") -EA 0
}
