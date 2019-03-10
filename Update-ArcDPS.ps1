<#
.SYNOPSIS
    Update-ArcDPS
    Update ArcDPS and optionally Start Guild Wars 2 after (so you can use
    a shortcut to this script instead of the traditional launcher)
.DESCRIPTION
    Reaches out to the hosting location for ArcDPS files, enumerates the
    directory index, recursively downloads all updated directories, and then
    places the base ArcDPS .dll into the Guild Wars 2 bin64 directory
    (essentially, search-path hijacking D3D9), and then optionally enabling
    additional ArcDPS projects (extras and build-templates) before optionally
    starting Guild Wars 2 automatically.
.PARAMETER Remove
    Removes ArcDPS and all Update-ArcDPS state and update.xml files.
.PARAMETER StartGW
    Automatically starts Guild Wars 2 after updating and enabling all additional
    extensions. Without setting this flag, ArcDPS is updated and installed and
    the powershell window will hang open, allowing you to review the output.
.PARAMETER CreateShortcut
    Automatically creates a shortcut on your Desktop that will run Update-ArcDPS
    with the -StartGW flag enabled for future runs.
.PARAMETER StateFile
    The path to the Update-ArcDPS XML state file, used to track your enablers
    and Guild Wars 2 path between runs. If it doesn't exist, it will be created.
    The default path is in your AppData folder, named update_arcdps.xml.
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
    SCRIPT VERSION: 0.1
    Requires: Powershell v5 or higher.

    Version History:
    0.1 - Initial public release

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
    [swtich]$CreateShortcut,
    [string]$StateFile=($env:APPDATA + '\update_arcdps.xml')
)

Function Download-Folder([string]$src,
                         [string]$dst,
                         [switch]$recursive,
                         [switch]$verbose) {
    # Ensure our inputs end with trailing slashes to make concatenation work
    #   predictably
    if ( $src -notmatch '\/$' ) {
        $src = "$src/"
    }
    if ( $dst -notmatch '\/$' ) {
        $dst = "$dst/"
    }
    # Make our destination if it doesn't exist
    if (!$(Test-Path($dst))) {
        New-Item $dst -type directory -Force
    }
    if ( $verbose.ispresent ) {
        Write-Host "`nRequested download of $src to $dst," `
          "recursive: $recursive`n"
    }

    # Collect our source
    $site = Invoke-WebRequest $src

    # Check the date that we last downloaded this src
    if ( Test-Path $dst/update.xml) {
        $last = Import-Clixml -path $dst/update.xml -EA SilentlyContinue
    } else {
        $last = [DateTime]'1 Jan 1970 00:01'
    }
    # Identify the modified dates in the source
    $dates = `
      $site.parsedhtml.childnodes[1].childnodes[1].childnodes[1].childnodes | `
      Where-Object {
        $_.nodeName -eq "#text"
    } | Select-Object -property data | `
      Select-String '\d{4}-\d{2}-\d{2} \d{2}:\d{2}'
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
        Write-Host "Update to $dst is available, downloading files`n"
        $doUpdate = $true
        $latest | Export-Clixml -path $dst/update.xml
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
    Write-Host "Looking for Guild Wars 2..."
    # Look in Program Files and (x86) by default
    $gw2path = Get-ChildItem -Path "C:\Program F*" -Include 'Gw2-64.exe' `
      -Recurse | select -ExpandProperty DirectoryName
    # If we find just one, nailed it
    if ($($gw2path | Measure-Object).Count -eq 1) {
        Write-Host "GW2 path identified as $gw2path."
        Write-Output $gw2path
    } else {
        # Look in all drive letters globally
        Write-Host "Unable to find in default path, expanding search."
        Get-CimInstance win32_logicaldisk -filter "DriveType='3'" | `
          ForEach-Object {
            $drive_letter = $_.DeviceID
            $gw2path = Get-ChildItem -Path "$drive_letter\" `
              -Include 'Gw2-64.exe' -Recurse | `
              select -ExpandProperty DirectoryName
            if ($($gw2path | Measure-Object).Count -eq 1) {
                Write-Host "GW2 path identified as $gw2path."
                Write-Output $gw2path
                break # Stop looking after first match
                return
            }
        }
        # Hard throw the error and abort if we couldn't find it
        $ErrorActionPreference = "Stop"
        $PSDefaultParameterValues['*:ErrorAction']='Stop'
        Throw "Unable to identify Guild Wars 2 location."
    }
}

if ($Remove) {
    # Find all the interesting files, and Gw2
    if (Test-Path $statefile) {
        Write-Host "Identified previous choices saved in $statefile`n"
        $state = Import-Clixml -Path $statefile
    } else {
        $state = @{}
        $state['binpath'] = $(Find-GuildWars2) + '\bin64\'
    }
    # These are the files that we're looking to remove
    $arcfiles = @( "README-links.txt",
     "arcdps.ini",
      "d3d9.dll",
      "d3d9.dll.md5sum",
      "update.xml"
    )
    # These are the extra directories
    $arcdirs = @( "buildtemplates", "extras" )

    # Remove the statefile since we won't need it
    Write-Host "Removing $statefile"
    Remove-Item -Force -ErrorAction SilentlyContinue -Path $statefile
    # Remove all of the ArcDPS main files
    $arcfiles | ForEach-Object {
        Write-Host ("Removing " + $state.binpath + $_)
        Remove-Item -Force -ErrorAction SilentlyContinue `
          -Path ($state.binpath + $_)
    }
    # Enumerate everything in the subdirectories
    $arcdirs | ForEach-Object {
        Get-ChildItem -ErrorAction SilentlyContinue ($state.binpath + $_) | `
          select -ExpandProperty Name | ForEach-Object {
            # and remove them from the base bindir, if they've been enabled
            Write-Host ("Removing " + $state.binpath + $_)
            Remove-Item -Force -ErrorAction SilentlyContinue `
              -Path ($state.binpath + $_)
        }
        # Also remove the subdirectory
        Write-Host ("Removing " + $state.binpath + $_)
        Remove-Item -Force -ErrorAction SilentlyContinue -Recurse `
          -Path ($state.binpath + $_)
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
} else { # If it's not already there, we'll go ahead and do initial setup
    $state = @{}

    $state['binpath'] = $(Find-GuildWars2) + '\bin64\'
    $correct = $false
    while ( ! $correct ) {
        Write-Host "Select from the following things to enable:"
        Write-Host "1) ArcDPS Extras"
        Write-Host "2) ArcDPS Build Templates"
        Write-Host "3) Both of the above!"
        $selection=$(Read-Host -Prompt "Selection")
        Switch -Exact ($selection) {
            1 {
                $state['enablers'] = @( "extras/" )
                $correct = $true
                break
            }
            2 {
                $state['enablers'] = @( "buildtemplates/" )
                $correct = $true
                break
            }
            3 {
                $state['enablers'] = @( "extras/", "buildtemplates/" )
                $correct = $true
                break
            }
            default {
                Write-Host "Invalid selection!`n`n"
            }
        }
    }
    $state | Export-Clixml -path $StateFile
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

# Enable everything you wanted to
$enablers = $state.enablers
$enablers | ForEach {
    Write-Host "Enabling $_ requested"
    ls "$dst$_" | ForEach {
        # Don't overwrite the main update.xml, please...
        if ( $_.name -ne "update.xml" ) {
            Copy-Item -path $_.fullname -destination $dst
        }
    }
}

Write-Host ""
Write-Host "Download of $src and enabling of $enablers is complete."

# Create the shortcut if you asked for it
if ($CreateShortcut) {
    $ShortcutFile = "$env:HOMEPATH\Desktop\Guild Wars 2 - ArcDPS.lnk"
    $Shortcut = $WScriptShell.CreateShortcut($ShortcutFile)
    $Shortcut.TargetPath = "`"$PSCommandPath`" -StartGW2"
    $Shortcut.WorkingDirectory = "$state.binpath"
    $Shortcut.Save()
}
# Start Guild Wars 2 if you asked for it
if ($StartGW2) {
    & $dst/../Gw2-64.exe
} else {
    pause
}
