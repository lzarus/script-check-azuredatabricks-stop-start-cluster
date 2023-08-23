Param(
    $ARM_SUBSCRIPTION_ID = "",
    $ARM_SUBSCRIPTION_NAME = "",
    $ARM_TENANT_ID = "",    
    $ARM_CLIENT_ID = "",    
    $ARM_CLIENT_SECRET = '', 
    $AZURE_DATABRICKS_APP_ID = "2ff814a6-3304-4ab8-85cb-cd0e6f879c1d", #Doesn't Change this value
    $ClusterConfigurations = @(   
    ("RG1", "ADB1", "Cluster1"),     
    ("RG2", "ABD1", "Cluster2")
    )
)
function authAzure {
    $SecureStringPwd = $ARM_CLIENT_SECRET | ConvertTo-SecureString -AsPlainText -Force
    $pscredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $ARM_CLIENT_ID, $SecureStringPwd
    Connect-AzAccount -ServicePrincipal -Credential $pscredential -Tenant $ARM_TENANT_ID
    Set-AzContext -SubscriptionId $ARM_SUBSCRIPTION_ID 
    accessToken
}
function accessToken {
    $accessToken = (Get-AzAccessToken -Resource $AZURE_DATABRICKS_APP_ID).Token
    StartDatabricksCluster $ClusterConfigurations $accessToken
}
function StartDatabricksCluster ($ClusterConfigurations, $accessToken) {
    foreach ($configuration in $ClusterConfigurations) {
        $ResourceGroupName = $configuration[0]
        $DatabricksWorkspaceName = $configuration[1]
        $DatabricksClusterName = $configuration[2]
        # Get workspace URL
        $workspace = Get-AzResource -ResourceGroupName $ResourceGroupName -ResourceName $DatabricksWorkspaceName -ResourceType 'Microsoft.Databricks/workspaces' -ApiVersion '2018-04-01'
        if (!$workspace) {
            Write-Output "Workspace $DatabricksWorkspaceName not found in resource group $ResourceGroupName"
            continue
        }
        $workspaceUrl = $workspace.Properties.workspaceUrl    
        $headers = @{
            "Authorization" = "Bearer $accessToken"
        }
        # Get cluster list
        $clusterListUrl = "https://$workspaceUrl/api/2.0/clusters/list"
        $clusterListResponse = Invoke-RestMethod -Uri $clusterListUrl -Method GET -Headers $headers
        $cluster = $clusterListResponse.clusters | Where-Object { $_.cluster_name -eq $DatabricksClusterName }
        if ($cluster -eq $null) {
            Write-Output "Cluster $DatabricksClusterName not found in Databricks workspace $DatabricksWorkspaceName"
            continue
        }  
        if ($cluster.state -eq "RUNNING") {
            Write-Output "Cluster $DatabricksClusterName is already running"
        }
        else {
            $clusterId = $cluster.cluster_id
            $startClusterUrl = "https://$workspaceUrl/api/2.0/clusters/start"
            $startClusterBody = @{
                cluster_id = $clusterId
            } | ConvertTo-Json
            Invoke-RestMethod -Uri $startClusterUrl -Method POST -Headers $headers -Body $startClusterBody
            Write-Output "Started cluster $DatabricksClusterName in Databricks workspace $DatabricksWorkspaceName"
        }
    }
}
authAzure