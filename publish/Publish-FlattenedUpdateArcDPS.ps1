$NewPsm1 = $PSScriptRoot/Update-ArcDPS/Update-ArcDPS.psm1
Copy-Item $PSScriptRoot/Update-ArcDPS.psm1.base $NewPsm1 -Force

$Private = @( Get-ChildItem -Path $PSScriptRoot/../Update-ArcDPS/Private/*.ps1 -ErrorAction SilentlyContinue )
$Public  = @( Get-ChildItem -Path $PSScriptRoot/../Update-ArcDPS/Public/*.ps1 -ErrorAction SilentlyContinue )
$FunctionsToExport = @()

ForEach $function_file in @($Private + $Public)) {
    Get-Content $function_file.Fullname >> $NewPsm1
    $FunctionsToExport += $function_file.Basename
}

$Functions = $FunctionsToExport -join ', '
Write-Output "Export-ModuleMember -Function $Functions" >> $NewPsm1


Publish-Module -Path $PSScriptRoot/Update-ArcDPS -NuGetApiKey $env:NUGETAPIKEY
