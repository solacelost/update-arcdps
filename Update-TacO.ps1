<#
.SYNOPSIS
    Update-TacO
    Update TacO and optionally start it afterwards (so you can use a shortcut
    to this script instead of creating your own TacO shortcut)
.DESCRIPTION
    Reaches out to the hosting locations for TacO and Tekkit's markers,
    backs up existing settings and data files, and updates them if necessary.
.PARAMETER Remove
    Removes TacO, all markers, and all Update-TacO state and update.xml files.
.PARAMETER StartTacO
    Automatically starts TacO after updating and enabling Tekkit's marker pack.
    Without setting this flag, TacO and Tekkit's are updated and installed and
    the powershell window will hang open, allowing you to review the output.
.PARAMETER CreateShortcut
    Automatically creates a shortcut on your Desktop that will run Update-TacO
    with the -StartTacO flag enabled for future runs (bypasses Execution Policy)
.PARAMETER SaneConfig
    Sets the configuration for TacO to some sane defaults to clutter your screen
    less than leaving everything on by default.
.PARAMETER TacOPath
    The path to which TacO, Tekkit's, and the Update-TacO state file should be
    saved. Defaults to the current user's AppData directory, in a folder named
    Update-TacO.
.PARAMETER Path
    The path to the .
.PARAMETER LiteralPath
    Specifies a path to one or more locations. Unlike Path, the value of
    LiteralPath is used exactly as it is typed. No characters are interpreted
    as wildcards. If the path includes escape characters, enclose it in single
    quotation marks. Single quotation marks tell Windows PowerShell not to
    interpret any characters as escape sequences.
.NOTES
    Name: Update-TacO.ps1
    Author: James Harmison
    SCRIPT VERSION: 0.4
    Requires: Powershell v5 or higher.

    Version History:
    0.4 - Corrected merge for uninstalled case
    0.3 - Adjusted default pathing to match Update-ArcDPS
    0.2 - Added Sane default configuration
    0.1 - Initial public release

    LICENSE:
    MIT License

    Copyright (c) 2020 James Harmison <jharmison@gmail.com>

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
.LINK
    https://www.github.com/solacelost/update-arcdps
#>
#Requires -Version 5

param (
    [switch]$Remove,
    [switch]$StartTacO,
    [switch]$CreateShortcut,
    [switch]$SaneConfig,
    [string]$InstallDirectory="$PSScriptRoot"
)

$scriptversion = '0.4'
$TacOPath = Join-Path "$InstallDirectory" "Update-TacO"
$TacOStateFile = Join-Path $TacOPath "state.xml"
$TacOTempDir = Join-Path "$env:TEMP" "TacO"
$TacODownloadDir = Join-Path "$TacOPath" "TacO"
New-Item -Type Directory -Path "$TacOPath" -name TacO -EA 0 >$null
$SaveFiles = (
    "activationdata.xml", "notepad.txt", "poidata.xml", "TacOConfig.xml"
)
$SaveDirs = ("Data", "POIs")

Function Merge-TacOConfig {
    param (
        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory = $true)] [string] $BaseXMLfile,
        [Parameter(Mandatory = $true)] [string] $OverrideXMLfile
    )

    if (-not $(Test-Path $BaseXMLFile)) {
        return [xml](Get-Content $OverrideXMLFile)
    }
    $originalXml = [xml](Get-Content $BaseXMLfile)
    $overrideXml = [xml](Get-Content $OverrideXMLfile)

    $RootElementname = $originalXML.DocumentElement.Name

    $BaseRootNode = $originalXml.SelectSingleNode("/$RootElementname")
    $OverrideRootNode = $OverrideXml.SelectSingleNode("/$RootElementname")

    ForEach ($ChildNode in $OverrideRootNode.ChildNodes)
    {
        $BaseNode = $BaseRootNode.SelectSingleNode($ChildNode.name)
        if ($BaseNode -ne $null) {
            $BaseNode.Data = $ChildNode.Data
        } else {
            $originalXml.DocumentElement.AppendChild($originalXml.ImportNode($ChildNode, $true))
        }
    }

    return $originalXml
}

if ($Remove) {
    Remove-Item $TacOPath -Recurse -EA 0
    Remove-Item "$env:HOMEPATH\Desktop\GW2TacO.lnk" -EA 0
    Remove-Item $MyInvocation.MyCommand.Definition -EA 0
    Write-Host "Update-TacO and the managed TacO installation has been removed."
    pause
    exit
}

# Maintain state in a dedicated xml file
if (Test-Path $TacOStateFile) {
    Write-Host "Identified previous choices saved in $TacOStateFile`n"
    $state = Import-Clixml -Path $TacOStateFile
} else { # If it's not already there, we'll go ahead and do initial setup
    $state = @{}
    $state['version'] = $scriptversion
    $state | Export-Clixml -path $TacOStateFile
}

Write-Host "Downloading TacO Information"
$latestRelease = Invoke-WebRequest https://github.com/BoyC/GW2TacO/releases/latest -Headers @{"Accept"="application/json"}
$json = $latestRelease.Content | ConvertFrom-Json

# Get the version
$tacoversion = $json.tag_name
$tacolinkversion = "https://github.com/BoyC/GW2TacO/releases/tag/$tacoversion"

#Get the download link (a little fragile)
$taco = $(Invoke-WebRequest $tacolinkversion).Links | Where-Object {$_.href -like "*/download/*"}
if ($taco -is [array]) {
    $tacolink = "https://github.com$($taco[0].href)"
} else {
    $tacolink = "https://github.com$($taco.href)"
}

Write-Host "Identified newest available TacO version $tacoversion."
if ( $state.ContainsKey('tacoversion') ) {
    $installedtaco = $state.tacoversion
    Write-Host "Installed version of TacO is: $installedtaco"
    if ($installedtaco -ne $tacoversion) {
        $updatetaco = $true
    } else {
        $updatetaco = $false
    }
} else {
    Write-Host "TacO is not currently installed."
    $updatetaco = $true
}

Write-Host "Downloading Tekkit's Workshop information"
$tekkits = $(Invoke-WebRequest http://www.tekkitsworkshop.net/)
$tekkitswidget = $(
    $tekkits.parsedHtml.body.getElementsByClassName("moduletable")
)
$tekkitsversion = $tekkitswidget.textContent.split('-')[-2].trim()
$tekkitslink = $tekkitswidget.firstChild.firstChild.href

Write-Host "Identified newest available Tekkit's Workshop version $tekkitsversion."
if ( $state.ContainsKey('tekkitsversion') ) {
    $installedtekkits = $state.tekkitsversion
    Write-Host "Installed version of Tekkit's is: $installedtekkits"
    if ($installedtekkits -ne $tekkitsversion) {
        $updatetekkits = $true
    } else {
        $updatetekkits = $false
    }
} else {
    Write-Host "Tekkit's is not currently installed."
    $updatetekkits = $true
}


if ($updatetaco) {
    if ( $(Get-Process -name GW2TacO -EA SilentlyContinue).count -gt 0 ) {
        # TacO is apparently running
        Write-Host "Exiting exiting GW2TacO process to facilitate update - " `
            "Please approve admin request"
        Start-Process -FilePath powershell.exe -Verb RunAs -ArgumentList "-Command Stop-Process -name GW2TacO"
        while (
            $(Get-Process -name GW2TacO -EA SilentlyContinue).count -gt 0
        ) { # TacO is still running
            sleep 1
        }
    }
    New-Item -Type Directory -Path $env:temp -name TacO -EA 0 >$null
    $SaveFiles | ForEach-Object {
        if ( Test-Path $TacODownloadDir/$_ ) {
            Write-Host "Saving $_"
            Move-Item -Force -Path $TacODownloadDir/$_ -Destination $TacOTempDir/
        }
    }
    $SaveDirs | ForEach-Object {
        $ThisDir = $_
        Write-Host "Saving $_"
        Get-ChildItem -Path "$TacODownloadDir/$_" -File -Recurse | ForEach-Object {
            $RelativePath = $_.FullName.Replace($TacODownloadDir, "")
            $ParentDirectory = Split-Path -Parent "$RelativePath"
            if ( Test-Path "$TacOTempDir/$RelativePath" ) {
                Remove-Item -Force -Path "$TacOTempDir/$RelativePath"
            }
            New-Item -Type Directory -Path "$TacOTempDir/$ParentDirectory" -EA 0 >$null
            Move-Item -Force -Path "$TacODownloadDir/$RelativePath" -Destination "$TacOTempDir/$ParentDirectory"
        }
    }
    Write-Host "Removing old version"
    Remove-Item -Force -Path $TacODownloadDir -Recurse
    New-Item -Type Directory -Path $TacOPath -name TacO -EA 0 >$null
    Write-Host "Downloading new version of TacO"
    Invoke-WebRequest -uri $tacolink -OutFile $TacODownloadDir\gw2taco.zip

    # Unzip it
    Write-Host "Extracting..."
    Expand-Archive -path $TacODownloadDir\gw2taco.zip -DestinationPath $TacODownloadDir

    # Recover save files
    $SaveFiles | ForEach-Object {
        if ( Test-Path $TacOTempDir/$_ ) {
            Write-Host "Restoring $_"
            Move-Item -Force -Path $TacOTempDir/$_ -Destination $TacODownloadDir/
        }
    }
    $SaveDirs | ForEach-Object {
        if ( Test-Path $TacOTempDir/$_ ) {
            $ThisDir = $_
            Write-Host "Restoring $_"
            Get-ChildItem -Path "$TacOTempDir/$_" -File -Recurse | ForEach-Object {
                $RelativePath = $_.FullName.Replace($TacOTempDir, "")
                $ParentDirectory = Split-Path -Parent "$RelativePath"
                if (! $(Test-Path "$TacODownloadDir/$RelativePath") ) {
                    New-Item -Type Directory -Path "$TacODownloadDir/$ParentDirectory" -EA 0 >$null
                    Move-Item -Force -Path "$TacOTempDir/$RelativePath" -Destination "$TacODownloadDir/$ParentDirectory"
                }
            }
        }
    }
    Remove-Item -Force -Path $TacOTempDir -Recurse -EA 0 >$null
    $state['tacoversion'] = $tacoversion
    $state | Export-Clixml -path $TacOStateFile
}

if ($updatetekkits) {
    # Download the Tekkit's Workshop all-in-one zip
    if (Test-Path $TacODownloadDir\POIs\tekkits.zip.bak) {
        Remove-Item $TacODownloadDir\POIs\tekkits.zip.bak -EA 0
    }
    if (Test-Path $TacODownloadDir\POIs\tekkits.zip) {
        Move-Item $TacODownloadDir\POIs\tekkits.zip $TacODownloadDir\POIs\tekkits.zip.bak -EA 0
    }
    Write-Host "Downloading Tekkit's"
    Invoke-WebRequest -uri http://tekkitsworkshop.net/index.php/gw2-taco/download/send/2-taco-marker-packs/32-all-in-one -OutFile $TacODownloadDir\POIs\tekkits.zip
    $state['tekkitsversion'] = $tekkitsversion
    $state | Export-Clixml -path $TacOStateFile
}

if ($SaneConfig) {
    Write-Host "Updating TacOConfig from Sane configuration defaults"
    $MergedConfig = Merge-TacOConfig "$TacODownloadDir\TacOConfig.xml" "$PSScriptRoot\TacOConfig_sane.xml"
    $MergedConfig.Save("$TacODownloadDir\TacOConfig.xml")
}

if ($CreateShortcut) {
    $TargetFile = "$TacODownloadDir\GW2TacO.exe"
    $ShortcutFile = "$env:HOMEPATH\Desktop\GW2TacO.lnk"
    if (Test-Path $ShortcutFile) {
        Write-Host "Removing old shortcut"
        Remove-Item $ShortcutFile -EA 0
    }
    Write-Host "Creating Run-As-Admin link for TacO on the Desktop"
    $WScriptShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WScriptShell.CreateShortcut($ShortcutFile)
    $Shortcut.TargetPath = $TargetFile
    $Shortcut.WorkingDirectory = $(Split-Path -path $TargetFile)
    $Shortcut.Save()
    # Fancy run as admin bit, just binary flipping the flag
    $bytes = [System.IO.File]::ReadAllBytes($ShortcutFile)
    $bytes[0x15] = $bytes[0x15] -bor 0x20 #set byte 21 (0x15) bit 6 (0x20) ON
    [System.IO.File]::WriteAllBytes($ShortcutFile, $bytes)
}

if ( $StartTacO ) {
    Write-Host "Starting GW2TacO as Admin as soon as Guild Wars 2 is open..."
    if ( $(Get-Process -name GW2TacO -EA SilentlyContinue).count -gt 0 ) {
        # TacO is apparently running
        Write-Host "Exiting exiting GW2TacO process to facilitate launching - " `
            "Please approve admin request"
        Start-Process -FilePath powershell.exe -Verb RunAs -ArgumentList "-Command Stop-Process -name GW2TacO"
        while (
            $(Get-Process -name GW2TacO -EA SilentlyContinue).count -gt 0
        ) { # TacO is still running
            sleep 1
        }
    }
    # Attempt to detect when the launcher is closed and Guild Wars 2 starts properly
    While ($GW2_Process = Get-Process -ProcessName Gw2-64 -EA 0) {
        if ($GW2_Process.Handles -le 1000) {
            sleep 5
        } else {
            break
        }
    }
    if ($GW2_Process -ne $null) {
        Start-Process -FilePath "$TacODownloadDir\GW2TacO.exe" -Verb RunAs -WorkingDirectory "$TacODownloadDir"
    }
} else {
    if (!$CreateShortcut) {
        pause
    }
}
