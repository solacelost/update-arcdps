Function Get-OSFamily() {
    <#
    .SYNOPSIS
        Guess what OS family we're running on
    .DESCRIPTION
        Check for the OS environment variable and a Windows-only cmdlet to guess
        Windows, check for /etc/os-release to guess *nix, and otherwise assume
        MacOS.
    .EXAMPLE
        Get-OSFamily
        # Returns:
        #  - Windows
        #  - Linux
        #  - Darwin
    .FUNCTIONALITY
        OS
    .LINK
        https://github.com/solacelost/update-arcdps
    #>
    If ($env:OS -ne $null -and $(Get-Command Get-CimInstance -EA 0) -ne $null) {
        "Windows"
    } Else {
        & uname -s
    }
}
