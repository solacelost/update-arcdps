Function Remove-UpdateArcDPS {

    # Import the statefile and remove it, or find GW2 to identify Arc files in
    if (Test-Path $statefile) {
        Write-Host "Identified previous choices saved in $statefile`n"
        $state = Import-Clixml -Path $statefile
        Write-Host "Removing $statefile"
        Remove-Item -Force -Path $statefile

        # Here is where I could handle version conflicts in state in the future

    } else {
        $state = @{}
        $state['binpath'] = $(Find-GuildWars2) + '\bin64\'
        $state['version'] = $scriptversion
    }

    # Remove this script
    Remove-Item -Force -Path $MyInvocation.MyCommand.Definition -EA 0

    # Remove Update-TacO.ps1
    if (Test-Path "$PSScriptRoot/Update-TacO.ps1") {
        & powershell.exe -ExecutionPolicy Bypass -File "$PSScriptRoot/Update-TacO.ps1" -InstallDirectory $InstallDirectory -Remove
    }

    if (Test-Path "$PSScriptRoot/TacOConfig_sane.xml") {
        Remove-Item -Force -Path "$PSScriptRoot/TacOConfig_sane.xml" -EA 0
    }

    # Remove anything left behind if we're in a proper subdirectory
    if ($(Split-Path $PSScriptRoot -Leaf) -eq "Update-ArcDPS") {
        Remove-Item -Force -Recurse -Path $PSScriptRoot -EA 0
    }

    # Remove the shortcut
    $ShortcutFile = "$DesktopDir\Guild Wars 2 - ArcDPS.lnk"
    if (Test-Path $ShortcutFile) {
        Write-Host "Removing $ShortcutFile"
        Remove-Item -Force -Path $ShortcutFile
    }

    # These are the main files that we're looking to remove
    $arcfiles = @( "README-links.txt",
     "arcdps.ini",
      "d3d9.dll",
      "d3d9.dll.md5sum",
      "update.xml"
    )
    # These are the (historical) extra directories
    $arcdirs = @( "buildtemplates", "extras" )

    # Remove all of the ArcDPS main files
    $arcfiles | ForEach-Object {
        $arcfile = $state.binpath + $_
        if (Test-Path $arcfile) {
            Write-Host ("Removing $arcfile")
            Remove-Item -Force -Path $arcfile
        }
    }
    # Enumerate everything in the subdirectories
    $arcdirs | ForEach-Object {
        Get-ChildItem -ErrorAction SilentlyContinue ($state.binpath + $_) | `
          select -ExpandProperty Name | ForEach-Object {
            # and remove them from the base bindir, if they've been enabled
            $arcfile = $state.binpath + $_
            if (Test-Path $arcfile) {
                Write-Host ("Removing $arcfile")
                Remove-Item -Force -Path $arcfile
            }
        }
        # Also remove the subdirectory
        $arcfile = $state.binpath + $_
        if (Test-Path $arcfile) {
            Write-Host ("Removing directory $arcfile")
            Remove-Item -Force -Recurse -Path $arcfile
        }
    }
    Write-Host "ArcDPS removed!"
    pause
    EXIT
}
