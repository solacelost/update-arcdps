Function Test-FolderPermissions {
    Write-Host "Verifying file permissions on necessary directories"
    $testpath = $($state.binpath + "/test.txt")
    Write-Output "Test" | Out-File -EA 0 -FilePath $testpath
    if ( $(Get-Content $testpath -EA SilentlyContinue | Measure-Object).count -eq 0 ) {
        $Acl = Get-Acl $state.binpath
        $UserPrincipal = $(Get-Acl $env:appdata).Owner
        $Ar = New-Object System.Security.AccessControl.FileSystemAccessRule($UserPrincipal, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
        $Acl.SetAccessRule($Ar)
        $modify_path = $state.binpath
        $modify_path_2 = $(Resolve-Path $(Join-Path $state.binpath ".."))
        $modify_path_3 = $(Join-Path $modify_path_2 "addons")
        $xml_path = $($env:temp + "/acl.xml")
        $Acl | Export-Clixml -path "$xml_path"

        Write-Host "We need to enable permissions for you to be able to install/update ArcDPS.`n"
        Write-Host "Please accept the Windows UAC prompt when it appears to enable this functionality."
        pause
        # This extremely long line renders our variables out and updates filesystem
        #   permissions for the binpath and binpath/../addons directories (both are
        #   necessary for the ability to update and run ArcDPS)
        Start-Process -FilePath powershell.exe -Verb RunAs -ArgumentList "`$Acl = `$(Import-Clixml '$xml_path') ; Set-Acl '$modify_path' `$Acl ; New-Item -Path '$modify_path_2' -Name 'addons' -ItemType 'directory' -EA 0 ; Set-Acl '$modify_path_3' `$Acl"
        Write-Host "The directory permissions should have been modified by the pop-up window.`n"
        Write-Host "We need to exit and relaunch the script to enable access."
        pause
        Remove-Item $xml_path
        Remove-Item $testpath
        exit
    }
    Remove-Item $testpath
}
