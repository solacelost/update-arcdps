Function Update-StateVersion {
    # Legacy stuff - ArcDPS no longer has extras or buildtemplates
    if ( $state.ContainsKey('enablers') ) {
        $state.Remove('enablers')
    }
    if ( ! $state.ContainsKey('version') ) {
        $state['version'] = '0.3'
    }
    if ( ! $state.ContainsKey('autoupdate') ) {
        if ($AutoUpdate) {
            $state['autoupdate'] = $true
        } else {
            Write-Host "Update-ArcDPS is now capable of keeping itself updated."
            $correct = $false
            $state['autoupdate'] = $(
                Get-YesOrNo -prompt "Would you like to enable automatic update of Update-ArcDPS?"
            )
        }
    }
    if ($state.version -ne $scriptversion) {
        if ($state.version.split('.')[1] -eq '3') {
            Write-Host "Update-ArcDPS is now capable of updating and launching TacO with Tekkit's Workshop marker pack enabled."
            $state['updatetaco'] = $(
                Get-YesOrNo -prompt "Would you like to enable Update-ArcDPS to manage TacO?" -DefaultYes
            )
            $state['version'] = "0.4.0"
        }
        if ($state.version -eq "0.4.0") {
            if ($state['updatetaco']) {
                Write-Host "Update-ArcDPS can load some sane defaults into your TacO settings to reduce the screen clutter. You can always reenable individual settings yourself."
                $load_taco_defaults = $(
                    Get-YesOrNo -prompt "Would you like to load sane default options for TacO?" -DefaultYes
                )
                Write-Host "Update-ArcDPS no longer assumes you want to launch TacO every time."
                $state['launchtaco'] = $(
                    Get-YesOrNo -prompt "Would you like to enable TacO autostart with the same shortcut you update it with?" -DefaultYes
                )
            }
            $state['version'] = '0.4.1'
        }
        if ($state.version -eq "0.4.1" -or $state.version -eq "0.4.2") {
            $vestigal_file = $(Join-Path "$env:APPDATA" "Bootstrap-ArcDPS.ps1")
            if (Test-Path "$vestigal_file") {
                Remove-Item -Force -Path "$vestigal_file" -EA 0
            }
            Write-Host "Update-ArcDPS has now moved its default installation location to enable cleaner file storage."
            $move_update_arcdps = $(
                Get-YesOrNo -prompt "Would you like to move Update-ArcDPS into a unique folder to keep the files more contained?" -DefaultNo
            )
            if ($move_update_arcdps) {
                Add-Type -AssemblyName System.Windows.Forms

                # Default installation directory is a subfolder underneath APPDATA
                $InstallDirectory = $(Join-Path "$env:APPDATA" "Update-ArcDPS")
                New-Item "$InstallDirectory" -ItemType "directory" -EA 0 | Out-Null

                # Prompt for an alternate installation directory
                $BrowserText = "Pick the installation location for Update-ArcDPS and press OK, or just Cancel to select the default ($InstallDirectory)"
                $FileBrowser = New-Object System.Windows.Forms.FolderBrowserDialog -Property @{
                    SelectedPath = "$InstallDirectory"
                    Description = "$BrowserText"
                }
                $ButtonPressed = $FileBrowser.ShowDialog()

                # If you picked a different directory, remove our other created directory
                if ($ButtonPressed -eq 'OK') {
                    if ($FileBrowser.SelectedPath -ne "$InstallDirectory") {
                        Remove-Item "$InstallDirectory" -recurse -force
                        $InstallDirectory = $FileBrowser.SelectedPath
                    }
                }
                $OldFiles = @(
                    "Update-ArcDPS.ps1",
                    "update_arcdps.xml",
                    "Update-TacO.ps1",
                    "Update-TacO",
                    "TacOConfig_sane.xml"
                )

                Write-Host "Moving old files and folders into $InstallDirectory"
                ForEach ($OldFile in $OldFiles) {
                    $OldFilePath = $(Join-Path "$env:APPDATA" $OldFile)
                    if (Test-Path "$OldFilePath") {
                        Write-Host "$OldFilePath --> $(Join-Path $InstallDirectory $OldFile)"
                        Move-Item "$OldFilePath" "$InstallDirectory"
                    }
                }
                Create-Shortcuts
                Write-Host ""
                Write-Host "You should relaunch the script via the new shortcut (Which you're free to rename/move now) on the Desktop."
                $state['version'] = '0.4.3'
                $state['install_directory'] = "$InstallDirectory"
                $StateFile = Join-Path "$InstallDirectory" update_arcdps.xml
                $state | Export-Clixml -Path "$StateFile"
                pause
                exit
            } else {
                $InstallDirectory = "$env:APPDATA"
                $state['install_location'] = "$InstallDirectory"
                Create-Shortcuts
            }
            $state['version'] = '0.4.3'
        }
    }
    # This is where update code should go for version-specific major changes
    # Ex:
    # if ($state['version'] -ne $scriptversion) {
    #     if ($state['version'] -eq "0.3.2") {
    #         <post 0.3.2 update code here>
    #         $state['version'] = "0.3.3"
    #     }
    #     if ($state['version'] -eq "0.3.3") {
    #         <post 0.3.3 update code here>
    #         $state['version'] = "0.4.0"
    #     }
    #     <etc until version catches up to $scriptversion>
    # }
    $state['version'] = $scriptversion
    $StateFile = Join-Path "$InstallDirectory" update_arcdps.xml
    $state | Export-Clixml -path $StateFile
}
