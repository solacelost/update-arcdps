<# Run this with the following:
powershell -nop -c "iex(New-Object Net.WebClient).DownloadString('https://github.com/solacelost/update-arcdps/raw/master/Bootstrap-ArcDPS.ps1')"
#>

# First, download the Update-ArcDPS.ps1 script
$ScriptPath = $env:APPDATA + '\Update-ArcDPS.ps1'
Invoke-WebRequest "https://github.com/solacelost/update-arcdps/raw/master/Update-ArcDPS.ps1" -OutFile $ScriptPath
# Then, set it to be locally executable
Unblock-File $ScriptPath

# Drop a shortcut on the Desktop to setup the script
$desktop = [system.environment]::GetFolderPath("Desktop")
$ShortcutFile = "$desktop\Update-ArcDPS Setup.lnk"
$WScriptShell = New-Object -ComObject WScript.Shell
$Shortcut = $WScriptShell.CreateShortcut($ShortcutFile)
$Shortcut.TargetPath = "%SystemRoot%\system32\WindowsPowerShell\v1.0\powershell.exe"
$Shortcut.Arguments = "-File $ScriptPath -CreateShortcut"
$Shortcut.Save()

# Now, spawn a new powershell window as admin to enable locally unsigned scripts

# Create a new process object that starts PowerShell
$newProcess = new-object System.Diagnostics.ProcessStartInfo "cmd.exe"
# Specify Set-ExecutionPolicy as the command to run
$newProcess.Arguments = "/c `"powershell.exe -c 'Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force -Scope LocalMachine ; pause'`""
# Indicate that the process should be elevated
$newProcess.Verb = "runas"

# Start the new process
[System.Diagnostics.Process]::Start($newProcess)
