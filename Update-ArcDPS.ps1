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
.PARAMETER StateFile
    The path to the Update-ArcDPS XML state file, used to track the  Guild Wars
    2 path and script version between runs. If it doesn't exist, it will be
    created. The default path is in your AppData folder, named
    update_arcdps.xml.
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
    SCRIPT VERSION: 0.3.4
    Requires: Powershell v5 or higher.

    Version History:
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
    [string]$StateFile="$env:APPDATA\update_arcdps.xml",
    [string]$SearchPath="C:\Program F*"
)

$scriptversion = '0.3.4'
$needsupdate = $false

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
        New-Item $dst -type directory -Force | Out-Null
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

Function Get-YesOrNo([string]$prompt) {
    $correct = $false
    While (!$correct) {
        $yesorno = $(Read-Host -Prompt $prompt).ToUpper()
        Switch -Exact ($yesorno) {
            "" {
                $false
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
                Write-Host "To answer in the negative, please either press 'Enter' or type the letter 'n' and press 'Enter.'"
                Write-Host "To answer in the affirmative, type the letter 'y' and press 'Enter.'"
                break
            }
        }
    }
}

$DesktopDir = [system.environment]::GetFolderPath("Desktop")
$SetupScript = "$DesktopDir\Update-ArcDPS Setup.lnk"
if (Test-Path $SetupScript) {
    Write-Host "Removing Bootstrapped setup shortcut"
    Remove-Item -Force -Path $SetupScript
}

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
if (Test-Path $StateFile) {
    Write-Host "Identified previous choices saved in $StateFile`n"
    $state = Import-Clixml -Path $StateFile
    # Legacy stuff - ArcDPS no longer has extras or buildtemplates
    if ( $state.ContainsKey('enablers') ) {
        $state.Remove('enablers')
    }
    if ( ! $state.ContainsKey('version') ) {
        $state['version'] = $scriptversion
    }
    if ( ! $state.ContainsKey('autoupdate') ) {
        if ($AutoUpdate) {
            $state['autoupdate'] = $true
        } else {
            Write-Host "Update-ArcDPS is now capable of keeping itself updated."
            $correct = $false
            $state['autoupdate'] = $(
                Get-YesOrNo -prompt "Would you like to enable this? (y/N)"
            )
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
} else { # If it's not already there, we'll go ahead and do initial setup
    $state = @{}
    $state['binpath'] = "$(Find-GuildWars2)\bin64\"
    $state['version'] = $scriptversion
    if ($AutoUpdate) {
        $state['autoupdate'] = $true
    } else {
        Write-Host "Update-ArcDPS is capable of keeping itself updated."
        $correct = $false
        $state['autoupdate'] = $(
            Get-YesOrNo -prompt "Would you like to enable AutoUpdate? (y/N)"
        )
    }
}

$state | Export-Clixml -path $StateFile

if ($state['autoupdate'] -or $AutoUpdate) {
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
            $PSScriptRoot/
        Remove-Item $PSScriptRoot/update-arcdps-$LatestVersion -recurse
        Remove-Item $PSScriptRoot/Update-ArcDPS.zip
        Write-Host "New version of Update-ArcDPS is installed. Please rerun this script via your normal shortcut."
        pause
        exit
    }
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
    Write-Host "Creating Desktop shortcut"
    $ShortcutFile = "$DesktopDir\Guild Wars 2 - ArcDPS.lnk"
    $WScriptShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WScriptShell.CreateShortcut($ShortcutFile)
    $Shortcut.TargetPath = "%SystemRoot%\system32\WindowsPowerShell\v1.0\powershell.exe"
    $Shortcut.Arguments = "-ExecutionPolicy Bypass -File $PSCommandPath -StartGW"
    $Shortcut.WorkingDirectory = $state.binpath
    $Shortcut.IconLocation = $state.binpath + '..\Gw2-64.exe'
    $Shortcut.Save()
}

# Start Guild Wars 2 if you asked for it
if ($StartGW) {
    Write-Host ""
    Write-Host "Starting Guild Wars 2"
    & $dst/../Gw2-64.exe
} else {
    pause
}
