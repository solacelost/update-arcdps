Function Update-UpdateArcDPS {
        Write-Host "Checking for updates to Update-ArcDPS script"
    $UpdateInfo = $(Invoke-WebRequest -UseBasicParsing https://api.github.com/repos/solacelost/update-arcdps/releases/latest)
    $LatestVersion = $(ConvertFrom-Json $UpdateInfo.content).tag_name
    if ($LatestVersion -ne $scriptversion) {
        Write-Host "Update-ArcDPS version $LatestVersion is available. Downloading." -NoNewLine
        Invoke-WebRequest -UseBasicParsing `
            -URI https://github.com/solacelost/update-arcdps/archive/$LatestVersion.zip `
            -OutFile $PSScriptRoot/Update-ArcDPS.zip
        Write-Host "." -NoNewLine
        Expand-Archive `
            -path $PSScriptRoot/Update-ArcDPS.zip `
            -DestinationPath $PSScriptRoot
        Write-Host "."
        Copy-Item `
            $PSScriptRoot/update-arcdps-$LatestVersion/*.ps1 `
            $PSScriptRoot/ `
            -Exclude Bootstrap-ArcDPS.ps1
        Copy-Item `
            $PSScriptRoot/update-arcdps-$LatestVersion/TacOConfig_sane.xml `
            $PSScriptRoot/
        Remove-Item $PSScriptRoot/update-arcdps-$LatestVersion -recurse
        Remove-Item $PSScriptRoot/Update-ArcDPS.zip
        Write-Host "New version of Update-ArcDPS is installed. Please rerun this script via your normal shortcut."
        pause
        exit
    }
}
