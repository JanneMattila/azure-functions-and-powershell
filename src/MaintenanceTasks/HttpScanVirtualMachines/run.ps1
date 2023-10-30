using namespace System.Net

param($Request, $TriggerMetadata)

Write-Host "Scan Virtual Machine function triggered by HTTP request."

$count = 1000
if ($Request.Query.Count) {
    $value = [int]$Request.Query.Count
    if ($value -ge 10 -and $value -le 1000) {
        $count = $value
    }
}

$response = . $env:FUNCTIONS_APPLICATION_DIRECTORY/Scripts/ScanVirtualMachines.ps1 -Count $count

Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body       = $response
    })
