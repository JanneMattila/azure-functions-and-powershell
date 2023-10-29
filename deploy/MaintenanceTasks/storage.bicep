param storageName string
param principalId string
param allowSharedKeyAccess bool
param location string = resourceGroup().location

// https://learn.microsoft.com/azure/role-based-access-control/built-in-roles#storage-blob-data-owner
var storageBlobDataOwnerRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b7e6dc6d-f1e8-4753-8033-0f276bb0955b')
var functionToStorageRoleAssignment = guid(storageName, storageBlobDataOwnerRoleId)

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
    name: storageName
    location: location
    kind: 'StorageV2'
    sku: {
        name: 'Standard_LRS'
    }
    properties: {
        supportsHttpsTrafficOnly: true
        defaultToOAuthAuthentication: true
        allowSharedKeyAccess: allowSharedKeyAccess
    }
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
    name: functionToStorageRoleAssignment
    properties: {
        principalId: principalId
        roleDefinitionId: storageBlobDataOwnerRoleId
    }
    scope: storageAccount
}

// Prepare storage connection string to Azure Functions
var storageKeyValue = storageAccount.listKeys().keys[0].value

output storageName string = storageName
output storageKey string = storageKeyValue
output storageConnectionString string = 'DefaultEndpointsProtocol=https;AccountName=${storageName};AccountKey=${storageKeyValue}'
