<#
Example invocation:
$result = .\Scripts\ScanVirtualMachines.ps1 -TagName "schedule" -Count 1000
$result.VirtualMachines
$result.Continues
#>
param (
    [string]$TagName = "schedule",
    [string]$PowerState = "PowerState/running",
    [switch] $ForceShutdown,
    [int]$Count = 10
)

class VirtualMachineData {
    [string] $Name
    [string] $Subscription
    [string] $ResourceGroup
    [string] $Location
    [string] $Schedule
}

$query = @"
resources 
| where type =~ 'Microsoft.Compute/virtualMachines'
| where isnotnull(tags['$TagName']) 
| extend schedule = tags['$TagName']
| extend PowerState = tostring(properties.extended.instanceView.powerState.code)
| where PowerState == '$PowerState'
| project subscriptionId, resourceGroup, name, schedule, location
| project-rename Subscription = subscriptionId, ResourceGroup = resourceGroup, Name = name, Schedule = schedule, Location = location
| order by Subscription, ResourceGroup, Name
"@
Write-Host $query

$results = Search-AzGraph -Query $query -First $Count
$results | Format-Table

$virtualMachines = New-Object System.Collections.ArrayList

foreach ($result in $results) {

    # Schedule is defined in "start-end" 24 hour format (UTC). Example: "8-16".
    if ($result.Schedule.Contains("-") -eq $false) {
        Write-Warning "Schedule tags value '$($result.Schedule)' for virtual machine $($result.Name) is not in correct 'start-end' in 24 hour format."
        continue
    }

    # Let's verify if that schedule is active now.
    $start = [int]$result.Schedule.Split("-")[0]
    $end = [int]$result.Schedule.Split("-")[1]
    $now = [int](Get-Date -Format "HH" -AsUTC)

    if ($start -lt $end) {
        # Example: 8-16
        if ($now -ge $start -and $now -le $end) {
            Write-Host "Virtual machine $($result.Name) is allowed to be running at $now due to schedule '$($result.Schedule)'."
            continue
        }
    }
    elseif ($start -gt $end) {
        # Example: 22-6
        if ($now -ge $start -or $now -le $end) {
            Write-Host "Virtual machine $($result.Name) is allowed to be running at $now due to schedule '$($result.Schedule)'."
            continue
        }
    }
    else {
        # Example: 8-8
        Write-Warning "Invalid schedule '$($result.Schedule)' for virtual machine $($result.Name). This machine will be shut down."
    }

    Write-Host "Virtual machine $($result.Name) should not be running at $now due to schedule '$($result.Schedule)'."

    if ($ForceShutdown) {
        Write-Host "Shutting down virtual machine $($result.Name)."
        Select-AzSubscription -SubscriptionId $result.Subscription
        Stop-AzVM -Name $result.Name -ResourceGroupName $result.ResourceGroup -Force -NoWait
    }

    $virtualMachineData = [VirtualMachineData]::new()
    $virtualMachineData.Name = $result.Name
    $virtualMachineData.Subscription = $result.Subscription
    $virtualMachineData.ResourceGroup = $result.ResourceGroup
    $virtualMachineData.Location = $result.Location
    $virtualMachineData.Schedule = $result.Schedule

    $virtualMachines.Add($virtualMachineData)
}

return [PSCustomObject]@{
    VirtualMachines = $virtualMachines
    Continues       = $null -ne $results.SkipToken
}
