[CmdletBinding(
    SupportsShouldProcess
)]
Param (
    [Parameter(HelpMessage = "Deployment target resource group")] 
    [string] $ResourceGroupName = "rg-maintenance-tasks",

    [Parameter(HelpMessage = "Application name prefix")] 
    [string] $AppPrefix,
    
    [Parameter(HelpMessage = "Notification webhook URL")] 
    [string] $WebhookUrl,

    [Parameter(HelpMessage = "Deployment target resource group location")] 
    [string] $Location = "North Europe",

    [string] $Template = "$PSScriptRoot\main.bicep",
    [string] $TemplateParameters = "$PSScriptRoot\main.bicepparam"
)

$ErrorActionPreference = "Stop"

$date = (Get-Date).ToString("yyyy-MM-dd-HH-mm-ss")
$deploymentName = "Local-$date"

if ([string]::IsNullOrEmpty($env:RELEASE_DEFINITIONNAME)) {
    Write-Host (@"
Not executing inside Azure DevOps Release Management.
Make sure you have done "Login-AzAccount" and
"Select-AzSubscription -SubscriptionName name"
so that script continues to work correctly for you.
"@)
}
else {
    $deploymentName = $env:RELEASE_RELEASENAME
}

# Target deployment resource group
if ($null -eq (Get-AzResourceGroup -Name $ResourceGroupName -Location $Location -ErrorAction SilentlyContinue)) {
    Write-Warning "Resource group '$ResourceGroupName' doesn't exist and it will be created."
    New-AzResourceGroup -Name $ResourceGroupName -Location $Location -Verbose
}

# Additional parameters that we pass to the template deployment
$additionalParameters = New-Object -TypeName hashtable
$additionalParameters['webhookUrl'] = $WebhookUrl

if ($false -eq [string]::IsNullOrEmpty($AppPrefix)) {
    # Override application name prefix from command line
    Write-Host "Overriding application name prefix with '$AppPrefix'"
    $additionalParameters['appPrefix'] = $AppPrefix
}

if ($PSCmdlet.ShouldProcess($ResourceGroupName)) {
    $result = New-AzResourceGroupDeployment `
        -DeploymentName $deploymentName `
        -ResourceGroupName $ResourceGroupName `
        -TemplateFile $Template `
        -TemplateParameterFile $TemplateParameters `
        @additionalParameters `
        -Mode Complete -Force `
        -Verbose
}
else {
    $result = New-AzResourceGroupDeployment `
        -WhatIf -WhatIfResultFormat FullResourcePayloads `
        -ResourceGroupName $ResourceGroupName `
        -TemplateFile $Template `
        -TemplateParameterFile $TemplateParameters `
        @additionalParameters `
        -Verbose
}

$result
