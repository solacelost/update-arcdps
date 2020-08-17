Function Find-GuildWars2() {
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
    param (
        [string]$Path="C:\Program F*"
    )
    Write-Log -Level Output "Looking for Guild Wars 2 in $Path"

    # Reference https://www.vistax64.com/threads/how-to-stopping-a-search-after-the-file-is-found.156738/
    # Find the first instance of Gw2-64.exe you can and stop looking
    $gw2path = &{
        Try {
            Get-ChildItem "$Path" -Filter "GW2-64.exe" -Recurse ` -ErrorAction SilentlyContinue | ForEach-Object {Throw $_}
        } Catch {
            $_[0].Exception.message
            Continue
        }
    }

    # Look in all drive letters globally if we didn't find it
    If ($($gw2path | Measure-Object).Count -eq 0) {
        Write-Log -Level Warning "Unable to find in expected path, expanding search."
        If ($env:OS -ne $null -and $(Get-Command Get-CimInstance -EA 0) -ne $null ) { # Probably Windows
            Get-CimInstance win32_logicaldisk -Filter "DriveType='3'" | ForEach-Object {
                $drive_letter = $_.DeviceID
                Write-Log -Level Output "Checking drive $drive_letter"
                $gw2path = &{
                    Try {
                        Get-ChildItem "$drive_letter\*" -Filter "GW2-64.exe" -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
                            Throw $_
                        }
                    } Catch {
                        $_[0].Exception.message
                        Continue
                    }
                }
                If ($gw2path) { Break }
            }
        } Else { # Probably Linux
            Write-Log -Level Output "Checking root of filesystem"
            $gw2path = &{
                Try {
                    Get-ChildItem "/" -Filter "GW2-64.exe" -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
                        Throw "$_"
                    }
                } Catch {
                    $_[0].Exception.message
                    Continue
                }
            }
        }
    }

    Write-Log -Level Output "Identified Guild Wars 2 in the following locations: $gw2path"

    $numresults = $($gw2path | Measure-Object).Count
    If ($numresults -eq 0) {
        # Hard throw the error and abort if we couldn't find it
        $ErrorActionPreference = "Stop"
        $PSDefaultParameterValues['*:ErrorAction']='Stop'
        Throw "Unable to identify Guild Wars 2 location."
    } ElseIf ($numresults -ne 1) {
        # It would appear that we found GW2 on multiple locations
        $correct = $false
        While ( ! $correct) {
            Write-Host "Select the installation you would like to add" `
                "ArcDPS to from the following choices by their number:"
            $gw2path | ForEach-Object {
                Write-Host ($gw2path.indexof($_) + 1)") $_"
            }
            $selection = ($(Read-Host -Prompt "Selection") -as [int]) - 1
            If ($selection -eq -1 -or $selection -ge $numresults) {
                Write-Host "Please select an index from the list provided."
            } Else {
                "$gw2path[$selection]"
                $correct = $true
            }
        }
    } else { # We found exactly one
        "$gw2path"
    }
}
