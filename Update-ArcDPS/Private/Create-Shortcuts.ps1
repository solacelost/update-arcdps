Function Create-Shortcuts {
    Write-Host "Creating Desktop shortcut"
    $ShortcutFile = "$DesktopDir\Guild Wars 2 - ArcDPS.lnk"
    $WScriptShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WScriptShell.CreateShortcut($ShortcutFile)
    $Shortcut.TargetPath = "%SystemRoot%\system32\WindowsPowerShell\v1.0\powershell.exe"
    $ScriptLocation = $(Join-Path $InstallDirectory Update-ArcDPS.ps1)
    $Shortcut.Arguments = "-ExecutionPolicy Bypass -File `"$ScriptLocation`" -InstallDirectory `"$InstallDirectory`" -StartGW"
    $Shortcut.WorkingDirectory = $state.binpath
    $IconLocation = $(Resolve-Path $(Join-Path $state.binpath "..\Gw2-64.exe")).Path
    $Shortcut.IconLocation = "$IconLocation"
    $Shortcut.Save()
    if ($state.updatetaco) {
        $args_to_pass = @('-CreateShortcut', '-InstallDirectory', "$InstallDirectory")
        if ($load_taco_defaults) {
            $args_to_pass += '-SaneConfig'
        }
        & powershell.exe -ExecutionPolicy Bypass -File "$InstallDirectory/Update-TacO.ps1" $args_to_pass
    }
}
