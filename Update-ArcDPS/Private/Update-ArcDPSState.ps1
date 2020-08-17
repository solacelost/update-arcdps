Function Update-ArcDPSState {
    $OldStateFile = $(Join-Path "$env:APPDATA" update_arcdps.xml)
    if (-not $(Test-Path "$StateFile") -and $(Test-Path "$OldStateFile")) {
        $oldstate = Import-Clixml -Path "$OldStateFile"
        if (-not $($oldstate.ContainsKey('install_directory'))) {
            Write-Host "Identified old-version previous choices saved in $OldStateFile`n"
            $state = $oldstate
        }
        Update-StateVersion
    } elseif (Test-Path "$StateFile") {
        Write-Host "Identified previous choices saved in $StateFile`n"
        $state = Import-Clixml -Path "$StateFile"
        Update-StateVersion
    } else { # If it's not already there, we'll go ahead and do initial setup
        $state = @{}
        $state['binpath'] = "$(Find-GuildWars2)\bin64\"
        $state['version'] = $scriptversion
        $state['install_directory'] = "$InstallDirectory"
        if ($AutoUpdate) {
            $state['autoupdate'] = $true
        } else {
            Write-Host "Update-ArcDPS is capable of keeping itself updated."
            $state['autoupdate'] = $(
                Get-YesOrNo -prompt "Would you like to enable AutoUpdate?"
            )
            Write-Host "Update-ArcDPS can also update GW2TacO with Tekkit's Workshop marker pack enabled."
            $state['updatetaco'] = $(
                Get-YesOrNo -prompt "Would you like to enable Update-ArcDPS to manage TacO and Tekkit's updates?" -DefaultYes
            )
            if ($state['updatetaco']) {
                Write-Host "Update-ArcDPS can load some sane defaults into your TacO settings to reduce the screen clutter. You can always reenable individual settings yourself."
                $load_taco_defaults = $(
                    Get-YesOrNo -prompt "Would you like to load these sane defaults?" -DefaultYes
                )
                Write-Host "Update-ArcDPS can also launch TacO for you every time you start the game."
                $state['launchtaco'] = $(
                    Get-YesOrNo -prompt "Would you like to enable TacO autostart?" -DefaultYes
                )
            }
        }
        $StateFile = Join-Path "$InstallDirectory" update_arcdps.xml
        $state | Export-Clixml -path $StateFile
    }
    if ("$OldStateFile" -ne $null -and $(Test-Path "$OldStateFile")) {
        Remove-Item -Force "$OldStateFile" -EA 0 | Out-Null
    }
}
