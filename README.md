# Introduction - powerbi-admin-scripts
PowerShell scripts that allow for easily completing Power BI admin activities, including
creating Azure DevOps pipelines

# Getting Started
1.	PowerShell Modules Needed for scripts to work
	a.  MicrosoftPowerBIMgmt
	b.  Az (Azure)
	c.  Fabric

# Scripts
1.	GetGatewayDatasources.ps1 - this script will allow you to list the datasources of a
	given data gateway
	
2.	TakeOverDatasetAndAssignSPtoGatewayDataSource.ps1 - this script will allow you to 
	take over a dataset with a service principal then bind that dataset to the data
	source(s) in the data gateway
	
	


# Contribute
If you would like to offer improvements or suggestions, please create a pull request.
