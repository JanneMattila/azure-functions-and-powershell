# Maintenance tasks deployment

```powershell
$webhookUrl = "...your-incoming-webhook-url-to-teams.."
$result = .\deploy.ps1 -WebhookUrl $webhookUrl

$result.Outputs | Format-List
$result.Outputs["funcApp"].value
$result.Outputs["funcAppUri"].value

$funcApp = $result.Outputs["funcApp"].value
$funcAppUri = $result.Outputs["funcAppUri"].value

pushd ../../src/MaintenanceTasks/
func azure functionapp publish $funcApp
# $accessToken = (Get-AzAccessToken).Token
# func azure functionapp publish $funcApp --access-token $accessToken
popd

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

$keys = Invoke-AzRestMethod -Path "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Web/sites/$funcApp/host/default/listkeys?api-version=2022-03-01" -Method POST
$masterKey = ($keys.content | ConvertFrom-Json).masterKey

curl --request POST -H "Content-Type: application/json" --data '{}' "https://$funcAppUri/admin/functions/TimerScanVirtualMachines?code=$masterKey"

# Clean up
Remove-AzResourceGroup -Name $resourceGroupName -Force
```