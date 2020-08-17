# Update-ArcDPS
# Copyright (c) 2020 James Harmison <jharmison@gmail.com>

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to
# deal in the Software without restriction, including without limitation the
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
# sell copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
# IN THE SOFTWARE.

$UpdateArcDPSFolder = Join-Path "$env:APPDATA" Update-ArcDPS
New-Item "$UpdateArcDPSFolder" -ItemType directory -EA 0 | Out-Null
Set-PSFLoggingProvider -Name filesystem -Enabled $false | Out-Null
Set-PSFLoggingProvider -Name LogFile -LogName 'UpdateArcDPS' -Enabled $true `
    -FilePath $(Join-Path "$UpdateArcDPSFolder" Update-ArcDPS.log)
Set-Alias Write-Log Write-PSFMessage

$PrivateFunctions = @(
    "Find-GuildWars2"
)
$PublicFunctions = @(
)

ForEach ($Function in $PrivateFunctions) {
    . $PSScriptRoot/Private/$Function.ps1
}
ForEach ($Function in $PublicFunctions) {
    . $PSScriptRoot/Public/$Function.ps1
    Export-ModuleMember -Function $Function
}
