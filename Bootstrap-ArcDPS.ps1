# Methodology (and chunks of code) taken directly from https://blogs.msdn.microsoft.com/virtual_pc_guy/2010/09/23/a-self-elevating-powershell-script/

<# Run this with the following:
powershell -NoProfile -Command "wget 'https://github.com/solacelost/update-arcdps/raw/master/Bootstrap-ArcDPS.ps1' -Outfile ($env:TEMP+'\bootstrap.ps1');Start-Process Powershell.exe -ArgumentList ('-ExecutionPolicy bypass -file '+$env:TEMP+'\bootstrap.ps1')"
#>

# Get the ID and security principal of the current user account
$myWindowsID = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$myWindowsPrincipal = New-Object System.Security.Principal.WindowsPrincipal($myWindowsID)

# Get the security principal for the Administrator role
$adminRole=[System.Security.Principal.WindowsBuiltInRole]::Administrator
# Check to see if we are currently running "as Administrator"
if ($myWindowsPrincipal.IsInRole($adminRole)) {
    # We are running "as Administrator" - so change the title and background color to indicate this
    $Host.UI.RawUI.WindowTitle = $myInvocation.MyCommand.Definition + "(Elevated)"
    $Host.UI.RawUI.BackgroundColor = "DarkBlue"
    clear-host
} else {
    $ScriptPath = $env:APPDATA + '\Update-ArcDPS.ps1'
    # First, download the Update-ArcDPS.ps1 script
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

    # Now, spawn a new powershell window to enable locally unsigned scripts

    # Create a new process object that starts PowerShell
    $newProcess = new-object System.Diagnostics.ProcessStartInfo "PowerShell"
    # Specify the current script path and name as a parameter
    $newProcess.Arguments = $myInvocation.MyCommand.Definition
    # Indicate that the process should be elevated
    $newProcess.Verb = "runas"

    # Start the new process
    [System.Diagnostics.Process]::Start($newProcess)
    exit
}

# This runs elevated as Administrator
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Confirm:$False -Force -Scope LocalMachine
pause
