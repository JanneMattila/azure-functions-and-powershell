param($Timer)

Write-Host "Scan Virtual Machine function triggered by timer."

$response = .\Scripts\ScanVirtualMachines.ps1 -Count 1000
Write-Host $response

Write-Host "Scan finished."
