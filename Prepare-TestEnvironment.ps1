$ErrorActionPreference = "Stop"

$PSVersionTable
Import-Module PackageManagement
Get-Command -Module PackageManagement

ForEach ($Dependency in @("Pester", "PSFramework")) {
    Find-Package $Dependency
    Get-Module $Dependency -ListAvailable
    Install-Module $Dependency -Force -SkipPublisherCheck
    Get-Module $Dependency -ListAvailable
    Update-Module $Dependency -Force
}

Get-Module
