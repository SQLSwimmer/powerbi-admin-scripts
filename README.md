# Introduction - powerbi-admin-scripts
PowerShell scripts that allow for easily completing Power BI admin activities, including
creating Azure DevOps pipelines

# Getting Started
1.	PowerShell Modules Needed for scripts to work
	a.  MicrosoftPowerBIMgmt
	b.  Az (Azure)
	c.  FabricPS-pbip - https://github.com/microsoft/Analysis-Services/tree/master/pbidevmode

# General Scripts
1.	GetGatewayDatasources.ps1 - this script will allow you to list the datasources of a given data gateway
	
2.	TakeOverDatasetAndAssignSPtoGatewayDataSource.ps1 - this script will allow you to take over a dataset with a service principal then bind that dataset to the data source(s) in the data gateway
	
# Azure DevOps Scripts
These scripts make the following assumptions:
1.	This process will only to be used for Development build/release - Why am I mentioning this?  Because there's this pesky thing called connections.  I am using the paradigm where we separate the semantic models from the reports (to encourage semantic model reuse).  In development, I am assuming the connection to the semantic model in the report will not change in a development deploy.  This means that whatever the connection is in the report, it will be the connection when it goes to the Power BI service. 

2.	Semantic models will already exist in the Power BI service that are used by reports - When you separate the semantic model from the report, when you create the report, the semantic model must already exist in the Power BI service in order to create that connection in the report.  This means that you will need to check in/sync your local branch with the remote branch where your semantic model creation/changes live before you can create any reports that use those semantic models.

3.	When deploying to any environment other than development, you will either have to use a different release pipeline that will modify the connection or modify your release pipeline to modify connections - There are options for editing the connection of a report/dataset.  You can use the PowerShell Fabric command-lets to do this.  The catch is that you need to have a really good naming convention in place to make this happen dynamically.  (This is still on my to-do list.)
   
These scripts rely on some variables that should be created in variable group:
	ReportsCodeWorkingDirectory - Name of the folder in the repo where the reports live.  See assumptions above
	DatasetsCodeWorkingDirectory - Name of the folder in the repo where semantic models live.  See assumptions above
	DatasetWorkspaceNameIndicator - Suffix used to identify semantic model workspace, e.g., Data, - Data , [Data], etc
	EnvironmentLabel - Environment that payload will be deployed to, e.g., Dev , [Dev], Test, [Test], - Test, etc
	PBIRootPath - if you have not structured your repo with the ReportsCodeWorkingDirectory and the DatasetsCodeWorkingDirectory at the root of your repo, then you will need to provide the path that root where they reside
	ServicePrincipalAppId - Service Principal App Id - created in Entra (fka, Azure Active directory) - ensure this App Id has at least contributor role in Power BI workspaces deploying to - This code assumes you have stored this as a secret variables, so you will need to map it to environment variable in the release pipeline called MY_MAPPED_SERVICEPRINCIPALAPPID
	ServicePrincipalSecret - Service Principal Secret value - This code assumes you have stored this as a secret variables, so you will need to map it to environment variable in the release pipeline - This code assumes you have stored this as a secret variables, so you will need to map it to environment variable in the release pipeline called MY_MAPPED_SERVICEPRINCIPALSECRET
	TenantId - TenantId for Power BI/Entra (fka, Azure Active Directory) - This code assumes you have stored this as a secret variables, so you will need to map it to environment variable in the release pipeline - This code assumes you have stored this as a secret variables, so you will need to map it to environment variable in the release pipeline called MY_MAPPED_TENANTID

1.	Buid PBIP Payloads in Azure DevOps.ps1 - this script will build a payload of files (based on the files that have changed between the current commit and previous commit) needed to deploy Power BI Projects (PBIP) and will put them in drop location to be consumed by a release pipeline

2.	Deploy PBIP files in Azure DevOps from Build Pipeline.ps1 - this script will pick up the files from the drop location created in Buid PBIP Payloads in Azure DevOps.ps1 and will use the Fabric PowerShell command-lets to deploy the payload(s)

# Contribute
If you would like to offer improvements or suggestions, please create a pull request.
