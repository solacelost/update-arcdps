Remove-Module Update-ArcDPS -ErrorAction Ignore
Import-Module "$PSScriptRoot/../Update-ArcDPS.psd1"
Import-Module "$PSScriptRoot/../Update-ArcDPS.psm1" -Force

InModuleScope Update-ArcDPS {
    Describe "Find-GuildWars2 Unit Tests" -tags "Unit" {
        Context "Files are where they belong" {
            BeforeAll {
                New-Item -ItemType directory "/Program Files Fake/Guild Wars 2/bin64"
                Write-Output "" > "/Program Files Fake/Guild Wars 2/GW2-64.exe"
            }
            AfterAll {
                Remove-Item "/Program Files Fake" -Recurse -Force
            }
            It "doesn't fail" {
                { Find-GuildWars2 } | Should -Not -Throw
            }
            It "finds Guild Wars 2" {
                Find-GuildWars2 | Should -Be "/Program Files Fake/Guild Wars 2"
            }
        }
        Context "Files are in an alternate, specific location" {
            BeforeAll {
                New-Item -ItemType directory "/Fake Games/Guild Wars 2/bin64"
                Write-Output "" > "/Fake Games/Guild Wars 2/GW2-64.exe"
            }
            AfterAll {
                Remove-Item "/Fake Games" -Recurse -Force
            }
            It "doesn't fail" {
                { Find-GuildWars2 -Path "/Fake Games" } | Should -Not -Throw
            }
            It "finds Guild Wars 2" {
                Find-GuildWars2 -Path "/Fake Games" | Should -Be "/Fake Games/Guild Wars 2"
            }
        }
        Context "Files are in an alternate, unspecified location" {
            BeforeAll {
                New-Item -ItemType directory "/Fake Games/Guild Wars 2/bin64"
                Write-Output "" > "/Fake Games/Guild Wars 2/GW2-64.exe"
            }
            AfterAll {
                Remove-Item "/Fake Games" -Recurse -Force
            }
            It "doesn't fail" {
                { Find-GuildWars2 } | Should -Not -Throw
            }
            It "finds Guild Wars 2" {
                Find-GuildWars2 | Should -Be "/Fake Games/Guild Wars 2"
            }
        }
        Context "Files don't exist" {
            It "fails to find Guild Wars 2" {
                { Find-GuildWars2 } | Should -Throw
            }
        }
        Context "Multiple files exist" {
            BeforeAll {
                New-Item -ItemType directory "/Fake Games/Guild Wars 2/bin64"
                Write-Output "" > "/Fake Games/Guild Wars 2/GW2-64.exe"
                New-Item -ItemType directory "/Program Files Fake/Guild Wars 2/bin64"
                Write-Output "" > "/Program Files Fake/Guild Wars 2/GW2-64.exe"
            }
            AfterAll {
                Remove-Item "/Fake Games" -Recurse -Force
                Remove-Item "/Program Files Fake" -Recurse -Force
            }
            It "doesn't fail" {
                { Find-GuildWars2 } | Should -Not -Throw
            }
            It "finds one copy of Guild Wars 2" {
                Find-GuildWars2 | Should -BeIn @("/Program Files Fake/Guild Wars 2", "/Program Files Fake/Guild Wars 2")
            }
        }
    }
}
