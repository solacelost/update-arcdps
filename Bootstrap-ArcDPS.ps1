<# Run this with the following:
powershell -c "[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12; ; iex(New-Object Net.WebClient).DownloadString('https://github.com/solacelost/update-arcdps/raw/0.5.0/Bootstrap-ArcDPS.ps1')"
#>
$installing_version = 'fix_download'

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

# Download Update-ArcDPS release
Write-Host "Downloading now." -NoNewLine
Invoke-WebRequest `
    -URI "https://github.com/solacelost/update-arcdps/archive/$installing_version.zip" `
    -OutFile "$InstallDirectory/Update-ArcDPS.zip" | Out-Null
Write-Host "." -NoNewLine
Expand-Archive `
    -path "$InstallDirectory/Update-ArcDPS.zip" `
    -DestinationPath "$InstallDirectory" | Out-Null
Write-Host "."
# This means I can set feature branches to be downloadable
$installing_version = $installing_version.Replace('/', '-')
Copy-Item `
    "$InstallDirectory/update-arcdps-$installing_version/*.ps1" `
    "$InstallDirectory/" `
    -Exclude Bootstrap-ArcDPS.ps1 | Out-Null
Copy-Item `
    "$InstallDirectory/update-arcdps-$installing_version/TacOConfig_sane.xml" `
    "$InstallDirectory/" | Out-Null
Remove-Item "$InstallDirectory/update-arcdps-$installing_version" -recurse | Out-Null
Remove-Item "$InstallDirectory/Update-ArcDPS.zip" | Out-Null

$desktop = [system.environment]::GetFolderPath("Desktop")
$ScriptPath = $(Join-Path "$InstallDirectory" "Update-ArcDPS.ps1")
# Drop a shortcut on the Desktop to setup the script
$ShortcutFile = "$desktop\Update-ArcDPS Setup.lnk"
Write-Host "Putting installation link at: $ShortcutFile"
$WScriptShell = New-Object -ComObject WScript.Shell
$Shortcut = $WScriptShell.CreateShortcut("$ShortcutFile")
$Shortcut.TargetPath = "%SystemRoot%\system32\WindowsPowerShell\v1.0\powershell.exe"
$Shortcut.Arguments = "-ExecutionPolicy Bypass -File `"$ScriptPath`" -InstallDirectory `"$InstallDirectory`" -CreateShortcut"
$Shortcut.Save()
Write-Host "`nUpdate-ArcDPS version $installing_version is bootstrapped! Run the `"Update-ArcDPS Setup`" shortcut on your desktop."
pause
