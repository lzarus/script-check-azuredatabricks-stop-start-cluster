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
    # Login using service principle
    Write-Output "Logging in using Azure service principle"
    az login --service-principal --username $ARM_CLIENT_ID --password $ARM_CLIENT_SECRET --tenant $ARM_TENANT_ID
    az account set -s $ARM_SUBSCRIPTION_ID
}

function accessToken {
    $accessToken = (az account get-access-token --resource $AZURE_DATABRICKS_APP_ID --query "accessToken" --output tsv)
    return $accessToken
}

function StartDatabricksCluster ($ClusterConfigurations) {
    # Get the access token from the Azure Automation secret
    $accessToken = accessToken
    foreach ($configuration in $ClusterConfigurations) {
        $ResourceGroupName = $configuration[0]
        $DatabricksWorkspaceName = $configuration[1]
        $DatabricksClusterName = $configuration[2]

        # Get workspace URL
        $workspaceUrl = az resource show --resource-group $ResourceGroupName --name $DatabricksWorkspaceName --resource-type Microsoft.Databricks/workspaces/clusters --query "properties.workspaceUrl" --output tsv
        if (-not $workspaceUrl) {
            Write-Host "Workspace $DatabricksWorkspaceName not found in resource group $ResourceGroupName"
            continue
        }       
        $headers = @{
            "Authorization" = "Bearer $accessToken"
        }
        
        # Get cluster list
        $clusterListUrl = "https://$workspaceUrl/api/2.0/clusters/list"
        $clusterListResponse = Invoke-RestMethod -Uri $clusterListUrl -Method GET -Headers $headers
        $cluster = $clusterListResponse.clusters | Where-Object { $_.cluster_name -eq $DatabricksClusterName }
        
        if ($cluster -eq $null) {
            Write-Host "Cluster $DatabricksClusterName not found in Databricks workspace $DatabricksWorkspaceName"
            continue
        }
        
        if ($cluster.state -eq "RUNNING") {
            Write-Host "Cluster $DatabricksClusterName is already running"
        }
        else {
            $clusterId = $cluster.cluster_id
            $startClusterUrl = "https://$workspaceUrl/api/2.0/clusters/start"
            $startClusterBody = @{
                cluster_id = $clusterId
            } | ConvertTo-Json
            Invoke-RestMethod -Uri $startClusterUrl -Method POST -Headers $headers -Body $startClusterBody
            Write-Host "Started cluster $DatabricksClusterName in Databricks workspace $DatabricksWorkspaceName"
        }
    }
}

authAzure
StartDatabricksCluster -ClusterConfigurations $ClusterConfigurations