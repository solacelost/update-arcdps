<# Run this with the following:
powershell -nop -c "iex(New-Object Net.WebClient).DownloadString('https://github.com/solacelost/update-arcdps/raw/master/Bootstrap-ArcDPS.ps1')"
#>

# First, download the Update-ArcDPS.ps1 script
$ScriptPath = $env:APPDATA + '\Update-ArcDPS.ps1'
Invoke-WebRequest "https://github.com/solacelost/update-arcdps/raw/master/Update-ArcDPS.ps1" -OutFile $ScriptPath
# Then, set it to be locally executable
Unblock-File $ScriptPath

$desktop = [system.environment]::GetFolderPath("Desktop")


# Drop a shortcut on the Desktop to change execution policy
$ShortcutFile = "$desktop\RemoteSigned Execution Policy.lnk"
$WScriptShell = New-Object -ComObject WScript.Shell
$Shortcut = $WScriptShell.CreateShortcut($ShortcutFile)
$Shortcut.TargetPath = "%SystemRoot%\system32\WindowsPowerShell\v1.0\powershell.exe"
$Shortcut.Arguments = "-Command 'Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force'"
$Shortcut.Save()
# Fancy run as admin bit, just binary flipping the flag
$bytes = [System.IO.File]::ReadAllBytes($ShortcutFile)
$bytes[0x15] = $bytes[0x15] -bor 0x20                   #set byte 21 (0x15) bit 6 (0x20) ON
[System.IO.File]::WriteAllBytes($ShortcutFile, $bytes)


# Drop a shortcut on the Desktop to setup the script
$ShortcutFile = "$desktop\Update-ArcDPS Setup.lnk"
$Shortcut = $WScriptShell.CreateShortcut($ShortcutFile)
$Shortcut.TargetPath = "%SystemRoot%\system32\WindowsPowerShell\v1.0\powershell.exe"
$Shortcut.Arguments = "-File $ScriptPath -CreateShortcut"
$Shortcut.Save()
