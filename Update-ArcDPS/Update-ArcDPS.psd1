@{
    RootModule = 'Update-ArcDPS.psm1'
    ModuleVersion = '0.6.0'
    GUID = '43bf8f3e-df8b-48ef-bbe9-0fe9be3690a0'
    Author = 'James Harmison'
    Copyright = '(c) 2020 James Harmison <jharmison@gmail.com>'
    Description = "Keeps ArcDPS, TacO, and Tekkit's Workshop marker pack updated."
    PowerShellVersion = '5.1'
    RequiredModules = @(
        @(@{ModuleName = 'PSFramework'; ModuleVersion = '1.0.19'})
    )
    FormatsToProcess = @()
    FunctionsToExport = @('Update-ArcDPS', 'Remove-UpdateArcDPS', 'Update-TacO', 'Update-UpdateArcDPS')
    AliasesToExport = @()
    CmdletsToExport = @()
    VariablesToExport = @()
    PrivateData = @{
        PSData = @{
            Tags = @('Guild Wars 2', 'ArcDPS', 'TacO')
            LicenseUri = 'https://raw.githubusercontent.com/solacelost/update-arcdps/master/LICENSE'
            ProjectUri = 'https://github.com/solacelost/update-arcdps'
            ReleaseNotes = 'https://raw.githubusercontent.com/solacelost/update-arcdps/master/CHANGELOG'
            RequireLicenseAcceptance = $false
        }
    }
}
