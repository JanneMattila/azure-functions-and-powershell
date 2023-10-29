param appPrefix string
param location string = resourceGroup().location

// Create unique name for our web site
var appName = '${appPrefix}${uniqueString(resourceGroup().id)}'
var storageSuffix = uniqueString(resourceGroup().id)
var appInsightsName = 'ai-${appPrefix}'

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
    name: 'id-${appPrefix}'
    location: location
}

module storage './storage.bicep' = {
    name: 'storage-deployment'
    params: {
        storageName: 'st${storageSuffix}'
        principalId: managedIdentity.properties.principalId
        allowSharedKeyAccess: false
        location: location
    }
}

module storageAppPackage './storage.bicep' = {
    name: 'storage-app-package-deployment'
    params: {
        storageName: 'stpkg${storageSuffix}'
        principalId: managedIdentity.properties.principalId
        allowSharedKeyAccess: true
        location: location
    }
}

module monitor 'monitor.bicep' = {
    name: 'monitor-deployment'
    params: {
        appName: appPrefix
        appInsightsName: appInsightsName
        principalId: managedIdentity.properties.principalId
        location: location
    }
}

resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
    name: 'asp-func'
    location: location
    sku: {
        name: 'Y1'
        tier: 'Dynamic'
    }
}

resource appServiceResource 'Microsoft.Web/sites@2022-09-01' = {
    name: appName
    location: location
    kind: 'functionapp'
    identity: {
        // type: 'SystemAssigned'
        type: 'UserAssigned'
        userAssignedIdentities: {
            '${managedIdentity.id}': {}
        }
    }
    properties: {
        siteConfig: {
            appSettings: [
                {
                    name: 'AzureWebJobsStorage__accountName'
                    value: storage.outputs.storageName
                }
                {
                    name: 'AzureWebJobsStorage__credential'
                    value: 'managedidentity'
                }
                {
                    name: 'AzureWebJobsStorage__clientId'
                    value: managedIdentity.properties.clientId
                }
                {
                    name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
                    value: storageAppPackage.outputs.storageConnectionString
                }
                {
                    name: 'WEBSITE_CONTENTSHARE'
                    value: toLower(appName)
                }
                {
                    name: 'FUNCTIONS_WORKER_RUNTIME'
                    value: 'powershell'
                }
                {
                    name: 'FUNCTIONS_EXTENSION_VERSION'
                    value: '~4'
                }
                {
                    name: 'WEBSITE_RUN_FROM_PACKAGE'
                    value: '1'
                }
                {
                    name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
                    value: monitor.outputs.appInsightsConnectionString
                }
                {
                    name: 'WEBSITE_TIME_ZONE'
                    value: 'E. Europe Standard Time'
                }
                {
                    name: 'AZURE_ACCOUNT_CLIENT_ID'
                    value: managedIdentity.properties.clientId
                }
            ]
            ftpsState: 'Disabled'
            minTlsVersion: '1.2'
            powerShellVersion: '7.2'
            http20Enabled: true
            use32BitWorkerProcess: false
        }
        serverFarmId: appServicePlan.id
        clientAffinityEnabled: false
        httpsOnly: true
    }
    tags: {
        'hidden-link: /app-insights-resource-id': resourceId('Microsoft.Insights/components', appInsightsName)
    }
}

output funcApp string = appName
output funcAppUri string = appServiceResource.properties.hostNames[0]
