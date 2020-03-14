<# Run this with the following:
powershell -c "[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12; ; iex(New-Object Net.WebClient).DownloadString('https://github.com/solacelost/update-arcdps/raw/0.4.1/Bootstrap-ArcDPS.ps1')"
#>

# First, download the Update-ArcDPS.ps1 script
$ScriptPath = $env:APPDATA + '\Update-ArcDPS.ps1'
Invoke-WebRequest "https://github.com/solacelost/update-arcdps/raw/0.4.1/Update-ArcDPS.ps1" -OutFile $ScriptPath

$desktop = [system.environment]::GetFolderPath("Desktop")

# Drop a shortcut on the Desktop to setup the script
$ShortcutFile = "$desktop\Update-ArcDPS Setup.lnk"
Write-Host "Putting script in: $ShortcutFile"
$WScriptShell = New-Object -ComObject WScript.Shell
$Shortcut = $WScriptShell.CreateShortcut($ShortcutFile)
$Shortcut.TargetPath = "%SystemRoot%\system32\WindowsPowerShell\v1.0\powershell.exe"
$Shortcut.Arguments = "-ExecutionPolicy Bypass -File `"$ScriptPath`" -CreateShortcut"
$Shortcut.Save()
Write-Host "`nUpdate-ArcDPS is bootstrapped! Run the `"Update-ArcDPS Setup`" shortcut on your desktop."
pause
