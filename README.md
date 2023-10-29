# Azure Functions and PowerShell

Azure Functions and PowerShell

## MaintenanceTasks

Create project structure:

```powershell
func init MaintenanceTasks --worker-runtime powershell
cd MaintenanceTasks
func new --name HttpScanVirtualMachines --template "HTTP trigger" --authlevel "function"
func new --name TimerScanVirtualMachines --template "Timer trigger" 
mkdir Scripts
echo "# Code here" > Scripts/ScanVirtualMachines.ps1
mkdir Tests
echo "# Tests here" > Tests/ScanVirtualMachines.Tests.ps1
code .
```

Start Storage Emulator:

```powershell
azurite --location $env:TEMP\azurite
```

Start Azure Functions:

```powershell
func start
```

Test Azure Functions:

```powershell
curl http://localhost:7071/api/ScanVirtualMachines

curl http://localhost:7071/api/ScanVirtualMachines?count=1000

curl --request POST -H "Content-Type: application/json" --data '{}' http://localhost:7071/admin/functions/TimerScanVirtualMachines
```
