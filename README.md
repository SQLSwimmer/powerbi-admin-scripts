# Introduction - powerbi-admin-scripts
PowerShell scripts that allow for easily completing Power BI admin activities, including
creating Azure DevOps pipelines

# Getting Started
1.	PowerShell Modules Needed for scripts to work
	- MicrosoftPowerBIMgmt
	- Az (Azure)
	- FabricPS-pbip - https://github.com/microsoft/Analysis-Services/tree/master/pbidevmode

# General Scripts
1.	GetGatewayDatasources.ps1 - this script will allow you to list the datasources of a given data gateway
	
2.	TakeOverDatasetAndAssignSPtoGatewayDataSource.ps1 - this script will allow you to take over a dataset with a service principal then bind that dataset to the data source(s) in the data gateway
	
# Azure DevOps Scripts
## Assumptions
These scripts make the following assumptions:
1.	This process will only to be used for Development build/release - Why am I mentioning this?  Because there's this pesky thing called connections.  I am using the paradigm where we separate the semantic models from the reports (to encourage semantic model reuse).  In development, I am assuming the connection to the semantic model in the report will not change in a development deploy.  This means that whatever the connection is in the report, it will be the connection when it goes to the Power BI service. 

2.	Semantic models will already exist in the Power BI service that are used by reports - When you separate the semantic model from the report, when you create the report, the semantic model must already exist in the Power BI service in order to create that connection in the report.  This means that you will need to check in/sync your local branch with the remote branch where your semantic model creation/changes live before you can create any reports that use those semantic models.

3.	When deploying to any environment other than development, you will either have to use a different release pipeline that will modify the connection or modify your release pipeline to modify connections - There are options for editing the connection of a report/dataset.  You can use the PowerShell Fabric command-lets to do this.  The catch is that you need to have a really good naming convention in place to make this happen dynamically.  (This is still on my to-do list.)
   
These scripts rely on some variables that should be created in variable group:
- **ReportsCodeWorkingDirectory** - Name of the folder in the repo where the reports live.  See assumptions above
- **DatasetsCodeWorkingDirectory** - Name of the folder in the repo where semantic models live.  See assumptions above
- **DatasetWorkspaceNameIndicator** - Suffix used to identify semantic model workspace, e.g., Data, - Data , [Data], etc
- **EnvironmentLabel** - Environment that payload will be deployed to, e.g., Dev , [Dev], Test, [Test], - Test, etc
- **PBIRootPath** - if you have not structured your repo with the ReportsCodeWorkingDirectory and the DatasetsCodeWorkingDirectory at the root of your repo, then you will need to provide the path that root where they reside
- **ServicePrincipalAppId** - Service Principal App Id - created in Entra (fka, Azure Active directory) - ensure this App Id has at least contributor role in Power BI workspaces deploying to - This code assumes you have stored this as a secret variables, so you will need to map it to environment variable in the release pipeline called MY_MAPPED_SERVICEPRINCIPALAPPID
- **ServicePrincipalSecret** - Service Principal Secret value - This code assumes you have stored this as a secret variables, so you will need to map it to environment variable in the release pipeline called MY_MAPPED_SERVICEPRINCIPALSECRET
- **TenantId** - TenantId for Power BI/Entra (fka, Azure Active Directory) - This code assumes you have stored this as a secret variables, so you will need to map it to environment variable in the release pipeline called MY_MAPPED_TENANTID
- **DefaultSecurityGroup** - The display name of the security group that will be added by default to any new workspace(s) that are created by the automated process 
- **DefaultSecurityGroupId** - The Entra object Id of the default security group contained in the DefaultSecurityGroup variable
- **DefaultSecurityGroupAccess** - The default workspace permission tha tis granted to the Entra security group contained in the DefaultSecurityGroup variable
- **PowerShellScriptPath** - PowerShell script files are used throughtout both build and release pipelines, this variable holds the value of the folder where these scirpt files reside in the repo
- **ProdReleaseTag** - Text to determine if a release should be published to production workspace(s)

## Scripts
**Basic folder**
This folder contains the scripts for basic functionality of deploying PBIPS.  If you are looking to do more advanced things, like check commit messages, set and check deploy variables, see the scripts in the Advanced folder.
1.	Build PBIP Payloads in Azure DevOps.ps1 - this script will build a payload of files (based on the files that have changed between the current commit and previous commit) needed to deploy Power BI Projects (PBIP) and will put them in drop location to be consumed by a release pipeline

2.	Deploy PBIP files in Azure DevOps from Build Pipeline.ps1 - this script will pick up the files from the drop location created in Buid PBIP Payloads in Azure DevOps.ps1 and will use the Fabric PowerShell command-lets to deploy the payload(s)

**Advanced folder**
This folder contains script files that some more advanced logic for deploying PBIPs.  The more advanced features are things like checking commit message, set and check deploy variables, copy all PS scripts.
1.  CheckForBuildArtifacts.ps1 - Checks to see if any build artifacts were created by the build pipeline and sets a variable appropriately.
2.  CopyPSScripts.ps1 - To ensure the most recent version of the PowerShell script files used in both the build and release pipelines, this script copies all PowerShell script files to the drop location.
3.  CreateUniquePayload.ps1 - Creates the Power BI Project payloads that will be consumed by the relase pipeline.  It uses a list of files changed since the previous commit to build this payload.  If the only changes are files being delted, then no payload is created and set the variable to false, otherwise it creates a list of unique Power BI Project payloads, then copyies them to the drop location ands set the variable to true.  This script also collects thecommit message and writes it to a files called COMMIT for subsequent used by the release pipeline.
4.  DeployPBIPPayload.ps1 - If the publish variable is true, this scrip t is executed.  This script reads the variables from the variable group and deploys the Power BI Project payloads from the build artifact created in the build pipeline.  It downloads and installs the needed Fabric PowerShell API command-lets, authenticates to the Power BI service using the Service Principal then deploys, on a workspace by workspace basis, the Power BI Project payloads.  If the workspace does not exist, it is created and the default security group is added with the default permissions.  This script also reads the COMMIT file to determine if the current changes should be released to production workspace(s).

# Contribute
If you would like to offer improvements or suggestions, please create a pull request.
