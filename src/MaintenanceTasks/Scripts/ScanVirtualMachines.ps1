<#
Example invocation:
$result = .\Scripts\ScanVirtualMachines.ps1 -Param1 "Hello" -Param2 123
$result.Parameter1
$result.Parameter2
#>
param (
    [string]$Param1,
    [int]$Param2
)

# Create a PowerShell object
$result = [PSCustomObject]@{
    Parameter1 = $Param1
    Parameter2 = $Param2
}

# Return the PowerShell object
return $result
