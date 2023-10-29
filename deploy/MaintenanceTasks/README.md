# Maintenance tasks deployment

```powershell
$result = .\deploy.ps1

$result.Outputs["funcApp"].value
$result.Outputs["funcAppUri"].value

$funcApp = $result.Outputs["funcApp"].value
$funcAppUri = $result.Outputs["funcAppUri"].value

cd ../../src/MaintenanceTasks/
func azure functionapp publish $funcApp
$subscriptionId = (Get-AzContext).Subscription.Id
$resourceGroupName = "rg-maintenance-tasks"
$functionName = "HttpScanVirtualMachines"

$functionKeys = Invoke-AzRestMethod -Path "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Web/sites/$funcApp/functions/$functionName/listkeys?api-version=2022-03-01" -Method POST

$code = ($functionKeys.content | ConvertFrom-Json).default

curl "https://$funcAppUri/api/ScanVirtualMachines?code=$code"
# Output:
# {
#   "VirtualMachines": [],
#   "Continues": false
# }

# Clean up
Remove-AzResourceGroup -Name $resourceGroupName -Force
```