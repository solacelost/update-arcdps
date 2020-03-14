<#
.SYNOPSIS
    Update-ArcDPS
    Update ArcDPS and optionally Start Guild Wars 2 after (so you can use
    a shortcut to this script instead of the traditional launcher)
.DESCRIPTION
    Reaches out to the hosting location for ArcDPS files, enumerates the
    directory index, recursively downloads all updated directories, and then
    places the base ArcDPS .dll into the Guild Wars 2 bin64 directory
    (essentially, search-path hijacking D3D9) before optionally starting Guild
    Wars 2 automatically.
.PARAMETER Remove
    Removes ArcDPS, all Update-ArcDPS state and update.xml files.
.PARAMETER StartGW
    Automatically starts Guild Wars 2 after updating. Without setting this flag,
    ArcDPS is updated and installed and the powershell window will hang open,
    allowing you to review the output.
.PARAMETER CreateShortcut
    Automatically creates a shortcut on your Desktop that will run Update-ArcDPS
    with the -StartGW flag enabled for future runs (bypasses Execution Policy)
.PARAMETER AutoUpdate
    Check for the latest release of Update-ArcDPS via GitHub API and download
    the latest version automatically, exiting with a notice about the update
    afterwards.
.PARAMETER InstallDirectory
    The path to the Update-ArcDPS XML state file, installation directory, and
    more. THe state file is used to track the  Guild Wars 2 path and script
    version between runs. If it doesn't exist, it will be created.
    The default path is in your AppData folder, and the state file is namedpdate_arcdps.xml.
.PARAMETER SearchPath
    The path that Update-ArcDPS should use to search for your Guild Wars 2
    directory.
.PARAMETER Path
    The path to the .
.PARAMETER LiteralPath
    Specifies a path to one or more locations. Unlike Path, the value of
    LiteralPath is used exactly as it is typed. No characters are interpreted
    as wildcards. If the path includes escape characters, enclose it in single
    quotation marks. Single quotation marks tell Windows PowerShell not to
    interpret any characters as escape sequences.
.NOTES
    Name: Update-ArcDPS.ps1
    Author: James Harmison
    SCRIPT VERSION: 0.4.4
    Requires: Powershell v5 or higher.

    Version History:
    0.4.4 - Corrected a plethora of various bugs during implementation of new
            directory location features'
    0.4.3 - Provided the ability to choose a directory to install Update-ArcDPS
    0.4.2 - Corrected variable type that caused TacO to error when launching
    0.4.1 - Added more options around Update-TacO, increased verbosity during
            various tasks, and provided for some sane TacO defaults
    0.4.0 - Integrated Update-TacO.ps1
    0.3.7 - Final fix for permissions - add the addons directory to the
            permissions fix for ArcDPS to store its own configuration in.
    0.3.6 - Fix for variable escaping under certain path situations for the
            last patch.
    0.3.5 - Check for write permissions on binpath and correct them if we don't
            have access.
    0.3.4 - Corrected scriptversion variable (I really need to automate updating
            versions between tags)
    0.3.3 - Fixed bad verb (Until vs While !)
    0.3.2 - Corrected some help pages, corrected behavior in search, and added
            auto-update functionality.
    0.3.1 - Corrected breaking bugs
    0.3   - Removed legacy content (buildtemplates, extras)
    0.2.2 - Corrected searching, added option for exact match
    0.2.1 - Adjusted bootstrap methodology
    0.2   - Enabled bootstrapping - Added Bootstrap-ArcDPS.ps1
            Removed requirement to modify execution policy and instead
              bypass it on the shortcuts
            Made the Gw2-64.exe search abuse traps and throw to make it faster
            Significant amount of embarrassing commit history during tests
            Updated documentation to reflect changes
    0.1   - Initial public release

    LICENSE:
    MIT License

    Copyright (c) 2019 James Harmison <jharmison@gmail.com>

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to
    deal in the Software without restriction, including without limitation the
    rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
    sell copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
    FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
    IN THE SOFTWARE.
.EXAMPLE
    PS> Update-ArcDPS.ps1 -StartGW
    << Update-ArcDPS will identify your Guild Wars 2 installation location,
        ask you which extras you want enabled, Download ArcDPS recursively,
        and save update information in update.xml files in the /bin64 directory,
        then save state in %appdata%\update_arcdps.xml and run Guild Wars 2 >>
    PS> Update-ArcDPS.ps1 -StartGW
    << Starting Update-ArcDPS a second time will result in a state file being
        found and loaded, then the ArcDPS website will be checked for updates
        before launching Guild Wars 2 automatically >>
.EXAMPLE
    PS> Update-ArcDPS.ps1 -Remove
    << Update-ArcDPS will load your state file if there is one, find Guild Wars
        2's working directory if there isn't one, and remove all files dropped
        by both ArcDPS and Update-ArcDPS before exiting >>
.LINK
    https://www.github.com/solacelost/update-arcdps
#>
#Requires -Version 5

param (
    [switch]$Remove,
    [switch]$StartGW,
    [switch]$CreateShortcut,
    [switch]$AutoUpdate,
    [string]$InstallDirectory=$(Join-Path "$env:APPDATA" "Update-ArcDPS"),
    [string]$SearchPath="C:\Program F*"
)

$scriptversion = '0.4.4'
$needsupdate = $false
$StateFile = Join-Path "$InstallDirectory" update_arcdps.xml

Function Download-Folder([string]$src,
                         [string]$dst,
                         [switch]$recursive,
                         [switch]$verbose) {
    # Ensure our inputs end with trailing slashes to make concatenation work
    #   predictably
    if ( $src -notmatch '\/$' ) {
        $src = "$src/"
    }
    if ( $dst -notmatch '[\/]$' ) {
        $dst = "$dst/"
    }
    # Make our destination if it doesn't exist
    if (!$(Test-Path($dst))) {
        New-Item $dst -type directory -Force  -EA 0 | Out-Null
    }
    if ( $verbose.ispresent ) {
        Write-Host "`nRequested download of $src to $dst," `
          "recursive: $recursive`n"
    }

    # Collect our source
    $site = Invoke-WebRequest $src

    # Check the date that we last downloaded this src
    if ( Test-Path $dst\update.xml) {
        $last = Import-Clixml -path $dst\update.xml -EA SilentlyContinue
    } else {
        $last = [DateTime]'1 Jan 1970 00:01'
    }
    # Identify the modified dates in the source
    $dates = $(
      $site.parsedhtml.childnodes[1].childnodes[1].childnodes[1].childnodes | `
        Where-Object {
          $_.nodeName -eq "#text"
        } | Select-Object -property data | `
        Select-String '\d{4}-\d{2}-\d{2} \d{2}:\d{2}'
    )
    # Pick out the newest as an integer
    $latest = $($dates | ForEach-Object {
        [DateTime]$_.matches.value
      } | sort)[-1]
    # If the latest update to this dst is newer than the last, do an update and
    #   update the file
    if ( $last.toUniversalTime() -lt $latest.toUniversalTime() ) {
        if ( $verbose.ispresent ) {
            Write-Host "Last updated on:          $last"
            Write-Host "Latest version available: $latest"
        }
        Write-Host "Update to $dst is available, downloading files"
        $doUpdate = $true
        $latest | Export-Clixml -path $dst\update.xml
    } else {
        if ( $verbose.ispresent ) {
            Write-Host "Last updated on:          $last"
            Write-Host "Latest version available: $latest"
        }
        Write-Host "No update to $dst, skipping files`n"
        $doUpdate = $false
    }

    # Iterate through the identified links
    $site.Links | ForEach {
        $link = $_.href
        # Standard links to arrange the table get trimmed out
        if ( $link -notmatch '^(\?|\/)' ) {
            # Indentify directories
            if ( $link -match '\/$' ) {
                if ( $verbose.ispresent ) {
                    Write-Host "  Sub-Directory: $src$link"
                }
                if ( $recursive.ispresent ) {
                    if ( $verbose.ispresent) {
                        Download-Folder -src "$src$link" -dst "$dst$link" `
                          -recursive -verbose
                    } else {
                        Download-Folder -src "$src$link" -dst "$dst$link" `
                          -recursive
                    }
                } else {
                    if ( $verbose.ispresent ) {
                        Write-Host "  Recursion not requested, skipping..."
                    }
                }
            } else {
                if ( $doUpdate ) {
                    Write-Host "  Downloading: $src$link"
                    Invoke-WebRequest "$src$link" -OutFile "$dst$link"
                }
            }
        }
    }
}

Function Find-GuildWars2() {
    Write-Host "Looking for Guild Wars 2 in $SearchPath"
    # Reference https://www.vistax64.com/threads/how-to-stopping-a-search-after-the-file-is-found.156738/
    # Find the first instance of Gw2-64.exe you can and stop looking
    # Look in Program Files and (x86) first
    $gw2path = &{
        trap {
            $error[0].exception.message
            continue
        }
        Get-ChildItem "$SearchPath" -Filter "Gw2-64.exe" -Recurse `
          -ErrorAction SilentlyContinue | ForEach-Object {
            throw $_.DirectoryName
        }
    }
    # Look in all drive letters globally if we didn't find it
    if ($($gw2path | Measure-Object).Count -eq 0) {
        Write-Host "Unable to find in expected path, expanding search."
        $gw2path = &{
            Get-CimInstance win32_logicaldisk -Filter "DriveType='3'" | `
              ForEach-Object {
                trap {
                    $error[0].exception.message
                    continue
                }
                $drive_letter = $_.DeviceID
                Write-Host "Checking drive $drive_letter"
                Get-ChildItem "$drive_letter\*" -Filter "Gw2-64.exe" -Recurse `
                  -ErrorAction SilentlyContinue | ForEach-Object {
                    throw $_.DirectoryName
                }
            }
        }
    }
    Write-Host "Identified Guild Wars 2 in the following locations:"
    Write-Host "$gw2path"
    $numresults = $($gw2path | Measure-Object).Count
    if ($numresults -eq 0) {
        # Hard throw the error and abort if we couldn't find it
        $ErrorActionPreference = "Stop"
        $PSDefaultParameterValues['*:ErrorAction']='Stop'
        Throw "Unable to identify Guild Wars 2 location."
    } elseif ($numresults -ne 1) {
        # It would appear that we found GW2 on multiple locations
        $correct = $false
        while ( ! $correct) {
            Write-Host "Select the installation you would like to add" `
                "ArcDPS to from the following choices by their number:"
            $gw2path | ForEach-Object {
                Write-Host ($gw2path.indexof($_) + 1)") $_"
            }
            $selection = ($(Read-Host -Prompt "Selection") -as [int]) - 1
            if ($selection -eq -1 -or $selection -ge $numresults) {
                Write-Host "Please select an index from the list provided."
            } else {
                Write-Output $gw2path[$selection]
                $correct = $true
            }
        }
    } else {
        Write-Output "$gw2path"
    }
}

Function Get-YesOrNo([string]$Prompt, [switch]$DefaultYes) {
    $correct = $false
    While (!$correct) {
        if ($DefaultYes) {
            $yesorno = $(Read-Host -Prompt "$Prompt (Y/N Default: Y)").ToUpper()
        } else {
            $yesorno = $(Read-Host -Prompt "$Prompt (Y/N Default: N)").ToUpper()
        }
        Switch -Exact ($yesorno) {
            "" {
                $DefaultYes
                $correct = $true
                break
            }
            "N" {
                $false
                $correct = $true
                break
            }
            "Y" {
                $true
                $correct = $true
                break
            }
            Default {
                Write-Host "'$yesorno' is not a valid option."
                if ($DefaultYes) {
                    Write-Host "To answer in the negative, type the letter 'n' and press 'Enter.'"
                    Write-Host "To answer in the affirmative, either press 'Enter' or type the letter 'y' and press 'Enter.'"
                } else {
                    Write-Host "To answer in the negative, either press 'Enter' or type the letter 'n' and press 'Enter.'"
                    Write-Host "To answer in the affirmative, type the letter 'y' and press 'Enter.'"
                }
                break
            }
        }
    }
}

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
                $state | Export-Clixml -path $StateFile
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
    $state | Export-Clixml -path $StateFile
}

$DesktopDir = [system.environment]::GetFolderPath("Desktop")

if ($Remove) {
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

# Maintain state in a dedicated xml file so we don't look for GW2 or prompt for
#   questions after initial setup

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
    $state | Export-Clixml -path $StateFile
}


if ($state.autoupdate -or $AutoUpdate) {
    Write-Host "Checking for updates to Update-ArcDPS script"
    $UpdateInfo = $(Invoke-WebRequest https://api.github.com/repos/solacelost/update-arcdps/releases/latest)
    $LatestVersion = $(ConvertFrom-Json $UpdateInfo.content).tag_name
    if ($LatestVersion -ne $scriptversion) {
        Write-Host "Update-ArcDPS version $LatestVersion is available. Downloading." -NoNewLine
        Invoke-WebRequest `
            -URI https://github.com/solacelost/update-arcdps/archive/$LatestVersion.zip `
            -OutFile $PSScriptRoot/Update-ArcDPS.zip
        Write-Host "." -NoNewLine
        Expand-Archive `
            -path $PSScriptRoot/Update-ArcDPS.zip `
            -DestinationPath $PSScriptRoot
        Write-Host "."
        Copy-Item `
            $PSScriptRoot/update-arcdps-$LatestVersion/*.ps1 `
            $PSScriptRoot/ `
            -Exclude Bootstrap-ArcDPS.ps1
        Copy-Item `
            $PSScriptRoot/update-arcdps-$LatestVersion/TacOConfig_sane.xml `
            $PSScriptRoot/
        Remove-Item $PSScriptRoot/update-arcdps-$LatestVersion -recurse
        Remove-Item $PSScriptRoot/Update-ArcDPS.zip
        Write-Host "New version of Update-ArcDPS is installed. Please rerun this script via your normal shortcut."
        pause
        exit
    }
}

Write-Host "Verifying file permissions on necessary directories"
$testpath = $($state.binpath + "/test.txt")
Write-Output "Test" | Out-File -EA 0 -FilePath $testpath
if ( $(Get-Content $testpath -EA SilentlyContinue | Measure-Object).count -eq 0) {
    $Acl = Get-Acl $state.binpath
    $UserPrincipal = $(Get-Acl $env:appdata).Owner
    $Ar = New-Object System.Security.AccessControl.FileSystemAccessRule($UserPrincipal, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
    $Acl.SetAccessRule($Ar)
    $modify_path = $state.binpath
    $modify_path_2 = $(Resolve-Path $(Join-Path $state.binpath ".."))
    $modify_path_3 = $(Join-Path $modify_path_2 "addons")
    $xml_path = $($env:temp + "/acl.xml")
    $Acl | Export-Clixml -path "$xml_path"

    Write-Host "We need to enable permissions for you to be able to install/update ArcDPS.`n"
    Write-Host "Please accept the Windows UAC prompt when it appears to enable this functionality."
    pause
    # This extremely long line renders our variables out and updates filesystem
    #   permissions for the binpath and binpath/../addons directories (both are
    #   necessary for the ability to update and run ArcDPS)
    Start-Process -FilePath powershell.exe -Verb RunAs -ArgumentList "`$Acl = `$(Import-Clixml '$xml_path') ; Set-Acl '$modify_path' `$Acl ; New-Item -Path '$modify_path_2' -Name 'addons' -ItemType 'directory' -EA 0 ; Set-Acl '$modify_path_3' `$Acl"
    Write-Host "The directory permissions should have been modified by the pop-up window.`n"
    Write-Host "We need to exit and relaunch the script to enable access."
    pause
    Remove-Item $xml_path
    Remove-Item $testpath
    exit
}
Remove-Item $testpath

$SetupScript = "$DesktopDir\Update-ArcDPS Setup.lnk"
if (Test-Path $SetupScript) {
    Write-Host "Removing Bootstrapped setup shortcut"
    Remove-Item -Force -Path $SetupScript
}

# Download ArcDPS
$src = 'https://www.deltaconnected.com/arcdps/x64/'
# To our GW2/bin64 directory
$dst = $state.binpath

# Recursively, so we grab all subfolders too
# NOTE: Download-Folder checks modification date and won't update if the listing
#   shows that we have the same version
Download-Folder -src $src -dst $dst -recursive

Write-Host "`n`n"

# Remove any legacy extras
@( "buildtemplates", "extras" ) | ForEach {
    $dll = "$($dst)d3d9_arcdps_$($_).dll"
    if ( Test-Path "$dll" ) {
        Write-Host "Removing legacy installation of $_"
        Remove-Item "$dll"
    }
}

Write-Host ""
Write-Host "Download of $src is complete."

# Create the shortcut if you asked for it
if ($CreateShortcut) {
    Write-Host ""
    Create-Shortcuts
}

# Start Guild Wars 2 if you asked for it
if ($StartGW) {
    Write-Host ""
    Write-Host "Starting Guild Wars 2"
    & $(Resolve-Path $(Join-Path "$dst" "../Gw2-64.exe")).Path
    Write-Host "Starting Update-TacO"
    if ($state.updatetaco) {
        if (! $(Test-Path "$PSScriptRoot/Update-TacO.ps1")) {
            Invoke-WebRequest `
                -URI https://raw.githubusercontent.com/solacelost/update-arcdps/$scriptversion/Update-TacO.ps1 `
                -OutFile "$PSScriptRoot/Update-TacO.ps1"
            Invoke-WebRequest `
                -URI https://raw.githubusercontent.com/solacelost/update-arcdps/$scriptversion/TacOConfig_sane.xml `
                -OutFile "$PSScriptRoot/TacOConfig_sane.xml"
        }
        $args_to_pass = @('-InstallDirectory', "$InstallDirectory")
        if ($load_taco_defaults) {
            $args_to_pass += '-SaneConfig'
        }
        if ($state['launchtaco']) {
            $args_to_pass += '-StartTacO'
        }
        & powershell.exe -ExecutionPolicy Bypass -File "$PSScriptRoot/Update-TacO.ps1" $args_to_pass
    }
} else {
    pause
}
