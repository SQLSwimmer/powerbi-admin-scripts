# Get list of datasources in specific data gateway
# 
# NOTE***** This is an INTERACTIVE script, it will prompt the user for their 
# credentials to connect to Azure.  Therefore, to execute this script successfully, 
# the user will need to have list and get permissions on the KeyVault.

# You will need to fill in any values that are denoted with <>, for example
# replace <Enter your service principal app id secret name in Key vault> 
# with Power-BI-Service-Principal-Demo-appid

param(
$KVName = "" # Enter the name of your Key Vault
,$SubscriptionId = "" # Enter your Subscription ID where Key Vault resides
,$AzureTenantId = "" # Enter your Azure Tenant ID
)

$KVAppIDSecretName = "<Enter secret name for your service principal app id in Key vault>" # --> edit this value
$KVAppIDSecretValueSecretName = "<Enter secret name for your service principal app name in key vault>" # --> edit this value
$KVGatewayIdSecretName = "<Enter secret name for your Data Gateway ID in key vault>" # --> edit this value
$KVPowerBITenantIDSecretName = "<Enter secret name for you Power BI tenant ID in key vault>" # --> edit this value


#Connect to Azure interactively
Connect-AzAccount -TenantId $AzureTenantId -Subscription $SubscriptionId

# Get KeyVault secrets
$AppId = Get-AzKeyVaultSecret -VaultName $KVName -Name $KVAppIDSecretName -AsPlainText
$SecretValue = Get-AzKeyVaultSecret -VaultName $KVName -Name $KVAppIDSecretValueSecretName -AsPlainText
$GatewayId = Get-AzKeyVaultSecret -VaultName $KVName -Name $KVGatewayIdSecretName -AsPlainText
$TenantId = Get-AzKeyVaultSecret -VaultName $KVName -Name $KVPowerBITenantIDSecretName -AsPlainText

# Connect as Service Principal - which should have admin rights
$password = ConvertTo-SecureString $SecretValue -AsPlainText -Force
$Cred = New-Object System.Management.Automation.PSCredential ($AppId, $password)
Connect-PowerBIServiceAccount -Tenant $TenantId -ServicePrincipal -Credential $Cred

# Create the URL to get list of data sources on gateway
$Url = "https://api.powerbi.com/v1.0/myorg/gateways/$GatewayId/datasources"

# Get list of data source from gateway
Invoke-PowerBIRestMethod -Url $Url -Method Get -Verbose 


