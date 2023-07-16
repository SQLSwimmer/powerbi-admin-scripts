# Assign Service Principal to take over dataset and gateway data sources

# Note:  The GetGatewayDatasources.ps1 script will need to be run first 
#        to get the datasetids needed in this script
# Also Note:  This is an interactive script, it will prompt the user for 
#        their credentials to connect to Azure.  Therefore, to execute this 
#        script successfully, the user will need to have list and get 
#        permissions on the KeyVault

# You will need to fill in any values that are denoted with <>, for example
# replace <Enter your service principal app id secret name in Key vault> 
# with Power-BI-Service-Principal-Demo-appid

param(
$DatasetId = "" # DatasetID from your workspace to take over
,$GroupId = "" # Workspace ID where dataset resides
,$KVName = "" # Name of Key Vault
,$TenantId = "" # Azure Tenant ID
,$SubscriptionId = "" # Subscription ID where Key Vault resides
)

$KVAppIDSecretName = "<Enter secret name for your service principal app id in Key vault>" # --> edit this value
$KVAppIDSecretValueSecretName = "<Enter secret name for your service principal secret value in key vault>" # --> edit this value
$KVGatewayIdSecretName = "<Enter secret name for your Data Gateway ID in key vault>" # --> edit this value
$KVServicePrincipalObjectIdSecretName = "<Enter secret name for your Service Principal Object ID>" # --> edit this value

# Depending on how many data sources there are, you may need to add/remove entries here
# Use the values returned from the GetGatewayDatasources.ps1
$GatewayDataSourceId1 = "<>" # populate this from the GetGatewayDatasources.ps1
$GatewayDataSourceId2 = "<>" # populate this from the GetGatewayDatasources.ps1


#Connect to Azure interactively
Connect-AzAccount -TenantId $TenantId -Subscription $SubscriptionId

# Get KeyVault secrets
$AppId = Get-AzKeyVaultSecret -VaultName $KVName -Name $KVAppIDSecretName -AsPlainText
$SecretValue = Get-AzKeyVaultSecret -VaultName $KVName -Name $KVAppIDSecretValueSecretName -AsPlainText
$GatewayId = Get-AzKeyVaultSecret -VaultName $KVName -Name $KVGatewayIdSecretName -AsPlainText
$ObjectId = Get-AzKeyVaultSecret -VaultName $KVName -Name $KVServicePrincipalObjectIdSecretName -AsPlainText

# Connect as Service Principal - which should have admin rights
$password = ConvertTo-SecureString $SecretValue -AsPlainText -Force
$Cred = New-Object System.Management.Automation.PSCredential ($AppId, $password)
Connect-PowerBIServiceAccount -Tenant $TenantId -ServicePrincipal -Credential $Cred

# Build out URLs and Body for API calls
$TakeOverUrl = "https://api.powerbi.com/v1.0/myorg/groups/$GroupId/datasets/$DatasetId/Default.TakeOver"
$BindToGatewayUrl = "https://api.powerbi.com/v1.0/myorg/groups/$GroupId/datasets/$DatasetId/Default.BindToGateway"

# Use the appropriate $Body variable based on the number of datasources 
# Note************** depending on how many data sources your dataset has, you may need to modify which line you use
#                    or even edit the line with multiple data sources to include as many as you need
$Body = "{'gatewayObjectId': '$GatewayId', 'datasourceObjectIds': ['$GatewayDataSourceId1']}"
#$Body = "{'gatewayObjectId': '$GatewayId', 'datasourceObjectIds': ['$GatewayDataSourceId1', '$GatewayDataSourceId2']}"

# Take over the dataset with Service Principal
Invoke-PowerBIRestMethod -Url $TakeOverUrl -Method Post -Verbose 

# Bind the dataset to the gateway datasource - Need to ensure all datasources in the dataset are included in the body parameter
Invoke-PowerBIRestMethod -Url $BindToGatewayUrl -Method Post -Body $Body -Verbose 


