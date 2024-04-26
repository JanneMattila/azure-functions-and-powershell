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

Use Pester:

```powershell
Install-Module Pester -Force
Import-Module Pester -PassThru
```

Test

```powershell
Invoke-Pester -Output Detailed src\MaintenanceTasks\Tests\ScanVirtualMachines.Tests.ps1
```

Output:

```powershell
Pester v5.5.0

Starting discovery in 1 files.
Discovery found 7 tests in 94ms.
Running tests.

Running tests from 'src\MaintenanceTasks\Tests\ScanVirtualMachines.Tests.ps1'
Describing ScanVirtualMachines
  [+] Validate scanning of vm-ok1 with schedule 8-16 at 10 should return 0 84ms (58ms|26ms)

Describing ScanVirtualMachines
  [+] Validate scanning of vm-ok2 with schedule 8-16 at 8 should return 0 29ms (26ms|3ms)

Describing ScanVirtualMachines
  [+] Validate scanning of vm-ok3 with schedule 8-16 at 16 should return 0 35ms (29ms|6ms)

Describing ScanVirtualMachines
  [+] Validate scanning of vm-ok4 with schedule 20-05 at 21 should return 0 36ms (33ms|3ms)

Describing ScanVirtualMachines
  [+] Validate scanning of vm-not-ok1 with schedule 8-16 at 7 should return 1 37ms (33ms|4ms)

Describing ScanVirtualMachines
  [+] Validate scanning of vm-not-ok2 with schedule 20-04 at 19 should return 1 31ms (27ms|4ms)

Describing ScanVirtualMachines
WARNING: Invalid schedule '20-20' for virtual machine vm-invalid. This machine will be shut down.
  [+] Validate scanning of vm-invalid with schedule 20-20 at 19 should return 1 28ms (24ms|3ms)
Tests completed in 610ms
Tests Passed: 7, Failed: 0, Skipped: 0 NotRun: 0
```
