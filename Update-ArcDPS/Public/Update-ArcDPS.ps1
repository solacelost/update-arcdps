Function Update-ArcDPS {
    <#
    .SYNOPSIS
        synopsis
    .DESCRIPTION
        description
    .PARAMETER Param
        param docs
    .EXAMPLE
        example call
        # example output explanation
    .FUNCTIONALITY
        GuildWars2
    .LINK
        https://github.com/solacelost/update-arcdps
    #>
    param (
        [switch]$Remove,
        [switch]$StartGW,
        [switch]$CreateShortcut,
        [switch]$AutoUpdate,
        [string]$InstallDirectory=$(Join-Path "$env:APPDATA" "Update-ArcDPS"),
        [string]$SearchPath="C:\Program F*"
    )

    $SetupScript = "$DesktopDir\Update-ArcDPS Setup.lnk"
    if (Test-Path $SetupScript) {
        Write-Host "Removing Bootstrapped setup shortcut"
        Remove-Item -Force -Path $SetupScript
    }

    # Download ArcDPS
    $utf8 = New-Object -TypeName System.Text.UTF8Encoding
    $src = 'https://www.deltaconnected.com/arcdps/x64/'
    $file = 'd3d9.dll'
    $sumfile = "$file.md5sum"
    # Save the expected md5sum as a string
    $arcdps_expected_sum = $utf8.GetString(
        $(Invoke-WebRequest -UseBasicParsing -Uri "$src$sumfile").Content
    ).Split(' ')[0]

    $md5 = New-Object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider

    $ErrorActionPreference = "SilentlyContinue"
    $installed_sum = $(Get-FileHash $(Join-Path $state.bindir '/d3d9.dll')).Hash.ToLower()
    $ErrorActionPreference = "Continue"

    If ( $installed_sum -eq $arcdps_expected_sum ) {
        Write-Host "Existing ArcDPS needs no update"
    } Else {
        Write-Host "Downloading update to ArcDPS"
        $arcdps = Invoke-WebRequest -UseBasicParsing -Uri "$src$file"

        Write-Host "Validating update checksum"
        $arcdps_sum = -Join $($md5.ComputeHash($arcdps.content) | ForEach {'{0:x2}' -f $_ })

        If ( $arcdps_expected_sum -eq $arcdps_sum ) {
            Write-Host "Expected checksum matches. Saving update to ArcDPS"
            [System.IO.File]::WriteAllBytes($(Join-Path $state.bindir '/d3d9.dll'), $arcdps.content)
        } Else {
            Write-Error -Message "ArcDPS download did not match expected MD5 sum. Not saving file. Please try again later." `
                -Category MetadataError -ErrorID MD5 -TargetObject $arcdps.content
        }
    }
