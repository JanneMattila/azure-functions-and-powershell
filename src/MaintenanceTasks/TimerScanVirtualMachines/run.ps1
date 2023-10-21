# Input bindings are passed in via param block.
param($Timer)

# Get the current universal time in the default string format.
$currentUTCtime = (Get-Date).ToUniversalTime()

# The 'IsPastDue' property is 'true' when the current function invocation is later than scheduled.
if ($Timer.IsPastDue) {
    Write-Host "PowerShell timer is running late!"
}

$response = .\Scripts\ScanVirtualMachines.ps1 -Param1 "Timer" -Param2 100
Write-Host $response

# Write an information log with the current time.a
Write-Host "PowerShell timer trigger function ran! TIME: $currentUTCtime"
