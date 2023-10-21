param($Timer)

Write-Host "Scan Virtual Machine function triggered by timer."

$response = .\Scripts\ScanVirtualMachines.ps1 -Count 1000 -ForceShutdown

if ($response.VirtualMachines.Count -eq 0) {
    Write-Host "No virtual machines found with schedule violation."
}
else {
    Write-Host "Found $($response.VirtualMachines.Count) virtual machines with schedule violation."

    $message = @"
Below virtual machines were still running outside the allowed schedule. They have now been de-allocated. `n

| Name | Resource Group | Subscription |
| ---- | -------------- | ------------ |

"@

    foreach ($vm in $response.VirtualMachines) {
        $message += "| $($vm.Name) | $($vm.ResourceGroup) | $($vm.Subscription) |`n"
    }

    $data = @{
        title = "Virtual Machine Schedule Violation"
        text  = $message
    }
    $body = ConvertTo-Json $data
    Invoke-RestMethod -Body $body -ContentType "application/json" -Method "POST" -DisableKeepAlive -Uri $url # $env:WebhookUrl
}

Write-Host "Scan finished."
