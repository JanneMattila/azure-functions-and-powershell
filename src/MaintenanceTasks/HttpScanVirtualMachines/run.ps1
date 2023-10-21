using namespace System.Net

param($Request, $TriggerMetadata)

Write-Host "Scan Virtual Machine function triggered by HTTP request."

$count = 1000
if ($Request.Query.Count) {
    $count = [int]$Request.Query.Count
}

$response = .\Scripts\ScanVirtualMachines.ps1 -Count $count

Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body       = $response
    })
