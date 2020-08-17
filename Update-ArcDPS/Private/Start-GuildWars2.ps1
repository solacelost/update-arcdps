Function Start-GuildWars2 {
    Write-Host ""
    Write-Host "Starting Guild Wars 2"
    & $(Resolve-Path $(Join-Path "$dst" "../Gw2-64.exe")).Path
    Write-Host "Starting Update-TacO"
    if ($state.updatetaco) {
        if (! $(Test-Path "$PSScriptRoot/Update-TacO.ps1")) {
            Invoke-WebRequest -UseBasicParsing `
                -URI https://raw.githubusercontent.com/solacelost/update-arcdps/$scriptversion/Update-TacO.ps1 `
                -OutFile "$PSScriptRoot/Update-TacO.ps1"
            Invoke-WebRequest -UseBasicParsing `
                -URI https://raw.githubusercontent.com/solacelost/update-arcdps/$scriptversion/TacOConfig_sane.xml `
                -OutFile "$PSScriptRoot/TacOConfig_sane.xml"
        }
        $args_to_pass = @('-InstallDirectory', "$InstallDirectory")
        if ($load_taco_defaults) {
            $args_to_pass += '-SaneConfig'
        }
        if ($state['launchtaco']) {
            $args_to_pass += '-StartTacO'
        }
        & powershell.exe -ExecutionPolicy Bypass -File "$PSScriptRoot/Update-TacO.ps1" $args_to_pass
    }
}
