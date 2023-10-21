using namespace System.Net

param($Request, $TriggerMetadata)

Write-Host "Scan Virtual Machine function triggered by HTTP request."

$count = 100
if ($Request.Query.Count) {
    $count = [int]$Request.Query.Count
}

$response = .\Scripts\ScanVirtualMachines.ps1 -Count $count

$url = "https://echo.jannemattila.com/api/echo"
$body = ConvertTo-Json $response
Invoke-RestMethod -Body $body -ContentType "application/json" -Method "POST" -DisableKeepAlive -Uri $url

Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body       = $response
    })
