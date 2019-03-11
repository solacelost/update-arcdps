<# Run this with the following:
powershell -nop -c "iex(New-Object Net.WebClient).DownloadString('https://github.com/solacelost/update-arcdps/raw/master/Bootstrap-ArcDPS.ps1')"
#>

# First, download the Update-ArcDPS.ps1 script
$ScriptPath = $env:APPDATA + '\Update-ArcDPS.ps1'
Invoke-WebRequest "https://github.com/solacelost/update-arcdps/raw/master/Update-ArcDPS.ps1" -OutFile $ScriptPath

$desktop = [system.environment]::GetFolderPath("Desktop")

# Drop a shortcut on the Desktop to setup the script
$ShortcutFile = "$desktop\Update-ArcDPS Setup.lnk"
$Shortcut = $WScriptShell.CreateShortcut($ShortcutFile)
$Shortcut.TargetPath = "%SystemRoot%\system32\WindowsPowerShell\v1.0\powershell.exe"
$Shortcut.Arguments = "-ExecutionPolicy Bypass -File $ScriptPath -CreateShortcut"
$Shortcut.Save()
