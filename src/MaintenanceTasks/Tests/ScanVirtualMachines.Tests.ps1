<#
 Invoke-Pester -Output Detailed .\Tests\ScanVirtualMachines.Tests.ps1
#>

Describe 'ScanVirtualMachines' -ForEach @(
    @{
        Name        = "vm-ok1";
        Schedule    = '8-16';
        CurrentTime = '10'
        Expected    = 0
    }
    @{
        Name        = "vm-ok2";
        Schedule    = '8-16';
        CurrentTime = '8'
        Expected    = 0
    }
    @{
        Name        = "vm-ok3";
        Schedule    = '8-16';
        CurrentTime = '16'
        Expected    = 0
    }
    @{
        Name        = "vm-ok4";
        Schedule    = '20-05';
        CurrentTime = '21'
        Expected    = 0
    }
    @{
        Name        = "vm--not-ok1";
        Schedule    = '8-16';
        CurrentTime = '7'
        Expected    = 1
    }
    @{
        Name        = "vm--not-ok2";
        Schedule    = '20-04';
        CurrentTime = '19'
        Expected    = 1
    }
) {
    It 'Validate scanning of <name> with schedule <schedule> at <currentTime> should return <expected>' {
        Mock -CommandName Search-AzGraph -MockWith { [PSCustomObject]@{ 
                Name     = $name
                Schedule = $schedule
            } }
        Mock -CommandName Get-Date -MockWith { $currentTime }

        $result = . $PSScriptRoot/../Scripts/ScanVirtualMachines.ps1
        $result.VirtualMachines.Count | Should -Be $expected
    }
}
