param appPrefix string
param location string = resourceGroup().location

// Create unique name for our web site
var appName = '${appPrefix}${uniqueString(resourceGroup().id)}'
var storageSuffix = uniqueString(resourceGroup().id)

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
                // {
                //     name: 'AzureWebJobsDisableHomepage'
                //     value: 'true'
                // }
                // {
                //     name: 'AzureWebJobsStorage'
                //     value: storage.outputs.storageConnectionString
                // }
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
                // {
                //     // https://learn.microsoft.com/en-us/azure/azure-functions/run-functions-from-deployment-package#fetch-a-package-from-azure-blob-storage-using-a-managed-identity
                //     name: 'WEBSITE_RUN_FROM_PACKAGE_BLOB_MI_RESOURCE_ID'
                //     value: managedIdentity.id
                // }
                // {
                //     name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
                //     value: monitor.outputs.appInsightsKey
                // }
                {
                    name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
                    value: monitor.outputs.appInsightsconnectionString
                }
                {
                    name: 'WEBSITE_TIME_ZONE'
                    value: 'E. Europe Standard Time'
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
}

output funcApp string = appName
output funcAppUri string = appServiceResource.properties.hostNames[0]
