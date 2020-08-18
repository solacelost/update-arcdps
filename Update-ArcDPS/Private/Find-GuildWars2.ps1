Function Find-GuildWars2([String]$Path = "/Program F*") {
    <#
    .SYNOPSIS
        Look for an installation of Guild Wars 2
    .DESCRIPTION
        Look for an installation of Guild Wars 2, halting early and returning
        the first one found.
    .PARAMETER Path
        The path to use as the basis of the initial search
    .EXAMPLE
        Find-GuildWars2 -Path "C:\Progra*"
        # Searched all folders matching the glob
    .FUNCTIONALITY
        GuildWars2
    .LINK
        https://github.com/solacelost/update-arcdps
    #>

    If ($(Get-ChildItem "$Path" | Measure-Object).Count -eq 0 -and $(Get-OSFamily) -ne "Windows") {
        Write-Log "Adjusting default path to '/usr/bin'"
        $Path = "/usr/bin"
    }

    Write-Log -Level Output "Looking for Guild Wars 2 in $Path"

    $gw2path = Get-ChildItem "$Path" -Filter "GW2-64.exe" -Recurse | Select-Object -First 1

    If ($($gw2path | Measure-Object).Count -eq 0) {
        Write-Log -Level Important "Unable to find in expected path, expanding search. This may take longer. If Guild Wars 2 cannot be found or the search takes too long, consider providing the search path."
        Switch ($(Get-OSFamily)) {
            "Windows" {
                Get-CimInstance win32_logicaldisk -Filter "DriveType='3'" | ForEach-Object {
                    $drive_letter = $_.DeviceID
                    # Double check to see if we found it already
                    If ($($gw2path | Measure-Object).Count -eq 0) {
                        Get-ChildItem "$drive_letter\*" -Filter "GW2-64.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
                    }
                }
            }
            "Linux" {
                $gw2path = Get-ChildItem "/" -Filter "GW2-64.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
            }
            "Darwin" {
                $gw2path = Get-ChildItem "/" -Filter "GW2-64.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
            }
        }
    }

    $numresults = $($gw2path | Measure-Object).Count
    If ($numresults -eq 1) {
        Split-Path -Path "$gw2path" -Parent
    } ElseIf ($numresults -eq 0) { # We couldn't find it
        $ErrorActionPreference = "Stop"
        $PSDefaultParameterValues['*:ErrorAction']='Stop'
        Throw "Unable to identify Guild Wars 2 location."
    } Else { # We shouldn't be here...
        $ErrorActionPreference = "Stop"
        $PSDefaultParameterValues['*:ErrorAction']='Stop'
        Throw "Unable to identify Guild Wars 2 location, found multiples ($gw2path)."
    }
}
