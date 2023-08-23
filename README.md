# PowerShell Script Documentation for Starting / Stopping Databricks Clusters

This PowerShell script is designed to start/stop Databricks clusters within specified Databricks workspaces. It utilizes Azure authentication information to connect, then retrieves cluster details to start from a list of configurations. The script employs Databricks API calls to interact with the clusters.

you can use scripts from two different options :
- use them with azure automation account 
- by running them as a powershell script

## Parameters

The script accepts the following parameters:

- **ARM_SUBSCRIPTION_ID**: Azure subscription ID.
- **ARM_SUBSCRIPTION_NAME**: Azure subscription name.
- **ARM_TENANT_ID**: Azure tenant ID.
- **ARM_CLIENT_ID**: Service principal (application) client ID used for authentication.
- **ARM_CLIENT_SECRET**: Service principal client secret for authentication.
- **AZURE_DATABRICKS_APP_ID**: Azure Databricks application ID (this value doesn't change).
- **ClusterConfigurations**: A list of cluster configurations in the form of tuples, each tuple containing the resource group name, Databricks workspace name, and cluster name.

## Functions

The script contains the following functions:

### authAzure

This function performs Azure authentication using the provided parameters (ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_TENANT_ID) and establishes an Azure subscription context using ARM_SUBSCRIPTION_ID.

### accessToken

This function obtains an access token from the Azure Databricks application using Get-AzAccessToken, then calls the StartDatabricksCluster function with the obtained access token.

### StartDatabricksCluster

This function takes two arguments: cluster configurations and an access token. For each cluster configuration, it performs the following operations:

- Retrieves the Databricks workspace URL using resource group and workspace name information.
- Constructs an authorization header for API calls using the access token.
- Retrieves the list of clusters in the Databricks workspace.
- Checks if the specified cluster is present in the list.
- If the cluster is found and not already running, it starts the cluster using an API call.

## Usage

To use this script, you need to provide the Azure authentication information, cluster configurations, and Azure Databricks application information. Then, execute the script to start the specified clusters.

Ensure you have the Azure PowerShell modules installed to run this script. You can install them using the following command:

```powershell
Install-Module -Name Az -AllowClobber -Force
After installing the modules, run the script using PowerShell. The script will authenticate the Azure Databricks application, retrieve the necessary access tokens, and start the clusters specified in the configurations.

Note: This script performs administrative operations on Databricks clusters. Ensure you have the appropriate permissions to perform these operations in your Azure and Databricks environment.


Conclusion
This PowerShell script provides an automated solution for starting Databricks clusters in an Azure environment. It uses Azure authentication to connect and Databricks API calls to interact with the clusters. By providing the proper parameters, you can easily start multiple Databricks clusters in a single script execution.