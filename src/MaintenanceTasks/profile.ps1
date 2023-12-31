# Azure Functions profile.ps1
#
# This profile.ps1 will get executed every "cold start" of your Function App.
# "cold start" occurs when:
#
# * A Function App starts up for the very first time
# * A Function App starts up after being de-allocated due to inactivity
#
# You can define helper functions, run commands, or specify environment variables
# NOTE: any variables defined that are not environment variables will get reset after the first execution

$ErrorActionPreference = "Stop"

# Authenticate with Azure PowerShell using MSI.
if ($env:MSI_SECRET) {
    Disable-AzContextAutosave -Scope Process | Out-Null
    if ($env:AZURE_ACCOUNT_CLIENT_ID) {
        # Use User Assigned Managed Identity
        Connect-AzAccount -Identity -AccountId $env:AZURE_ACCOUNT_CLIENT_ID
    }
    else {
        # Use System Assigned Managed Identity
        Connect-AzAccount -Identity
    }
}

# You can also define functions or aliases that can be referenced in any of your PowerShell functions.