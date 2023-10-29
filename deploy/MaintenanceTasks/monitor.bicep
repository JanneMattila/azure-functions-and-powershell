param appName string
param principalId string
param location string

// https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#monitoring-metrics-publisher
var monitoringMetricsPublisherRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '3913510d-42f4-4e42-8a64-420c390055eb')
var functionToMonitorRoleAssignment = guid(resourceGroup().id, monitoringMetricsPublisherRoleId)

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: 'log-${appName}'
  location: location
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: 'ai-${appName}'
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspace.id
    DisableLocalAuth: true
  }
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: functionToMonitorRoleAssignment
  properties: {
    principalId: principalId
    roleDefinitionId: monitoringMetricsPublisherRoleId
  }
  scope: appInsights
}

output appInsightsconnectionString string = appInsights.properties.ConnectionString
