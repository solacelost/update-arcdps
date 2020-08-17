Function Get-YesOrNo([string]$Prompt, [switch]$DefaultYes) {
    $correct = $false
    While (!$correct) {
        if ($DefaultYes) {
            $yesorno = $(Read-Host -Prompt "$Prompt (Y/N Default: Y)").ToUpper()
        } else {
            $yesorno = $(Read-Host -Prompt "$Prompt (Y/N Default: N)").ToUpper()
        }
        Switch -Exact ($yesorno) {
            "" {
                $DefaultYes
                $correct = $true
                break
            }
            "N" {
                $false
                $correct = $true
                break
            }
            "Y" {
                $true
                $correct = $true
                break
            }
            Default {
                Write-Host "'$yesorno' is not a valid option."
                if ($DefaultYes) {
                    Write-Host "To answer in the negative, type the letter 'n' and press 'Enter.'"
                    Write-Host "To answer in the affirmative, either press 'Enter' or type the letter 'y' and press 'Enter.'"
                } else {
                    Write-Host "To answer in the negative, either press 'Enter' or type the letter 'n' and press 'Enter.'"
                    Write-Host "To answer in the affirmative, type the letter 'y' and press 'Enter.'"
                }
                break
            }
        }
    }
}
