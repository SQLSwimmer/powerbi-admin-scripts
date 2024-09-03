write-host "Starting.."

# ********************************** Build Working Directory and paths ******************************************
#Get working directory
$workingDirectory = $env:System_ArtifactsDirectory + "\drop" 
write-host "Working directory:  " $workingDirectory

#Build the base path 
$basePath = $workingDirectory 
write-host "basePath:  " $basePath
$basePBIPPath = $workingDirectory + "\$env:PBIRootpath"
write-host "basePBIPPath:  " $basePBIPPath

# Get the default security group and access to add to workspaces
$defaultSecurityGroupId = $env:DefaultSecurityGroupId
$defaultSecurityGroupAccess = $env:DefaultSecurityGroupAccess

# Build out the body of the permissions
$workspacePermissions = @(
    @{
    "principal" = @{
        "id" = $defaultSecurityGroupId
        "type" = "group"
    }
    "role"= $defaultSecurityGroupAccess
    }
)
# Check commit message, if it contains prodReleaseTag, then it's a prod release, otherwise it's non-prod
# because we cannot reach in the build variables, we wrote the commit message to the drop directory in a
# file called COMMIT during the build process
# If the contents of the file contain the prodReleaseTag, then it is a prod release
# Read the content of the COMMIT file
$commitMessageFilePath = "$workingDirectory\COMMIT"
$commitMessage = Get-Content -Path $commitMessageFilePath -Raw
Write-Host "Commit message:  " $commitMessage

# if commit message contains text from variable, ProdReleaseTag, then it's a prod release
$prodReleaseTag = $env:ProdReleaseTag
if ($commitMessage -like "*$prodReleaseTag*") {
    $EnvLabel = ""
    Write-Host "prod release, so no environment label needed"
}
else {
    $EnvLabel = "$env:EnvironmentLabel"
    Write-Host "non-prod release, so using EnvironmentLabel"
}
write-host "Environment Label:" $EnvLabel

# Now look to see if there are any PBIP artifacts to deploy
if (-Not (Test-Path -Path $basePBIPPath)) {
    write-host "There are no PBIP files to deploy, exiting release"
    EXIT
}
else {

	# ********************************** Download and install needed modules ******************************************
	# Download modules and install for fabricps-pbip
	New-Item -ItemType Directory -Path ".\modules" -ErrorAction SilentlyContinue | Out-Null
	@("https://raw.githubusercontent.com/microsoft/Analysis-Services/master/pbidevmode/fabricps-pbip/FabricPS-PBIP.psm1"
	, "https://raw.githubusercontent.com/microsoft/Analysis-Services/master/pbidevmode/fabricps-pbip/FabricPS-PBIP.psd1") |% {
		Invoke-WebRequest -Uri $_ -OutFile ".\modules\$(Split-Path $_ -Leaf)"
	}
	if(-not (Get-Module Az.Accounts -ListAvailable)) { 
		write-host "Installing Az.Accounts module.."
		Install-Module Az.Accounts -Scope CurrentUser -Force
		write-host "Done installing Az.Accounts module"
	}

	write-host "Importing FabricPS-PBIP.."
	Import-Module ".\modules\FabricPS-PBIP" -Force
	write-host "Done Importing FabricPS-PBIP"



	#************************************************** Now Authenticate with Service Principal ********************
	write-host "Starting FabricAuthToken.."
	Set-FabricAuthToken -servicePrincipalId "$env:MY_MAPPED_SERVICEPRINCIPALAPPID" -servicePrincipalSecret "$env:MY_MAPPED_SERVICEPRINCIPALSECRET" -tenantId "$env:MY_MAPPED_TENANTID" -reset
	write-host "Done with FabricAuthToken"



	#************************************************** Deploy payloads *******************************************
	$workspaces = get-childitem -Path $basePBIPPath| where-object {$_.PSIsContainer}

	# We want to deploy on a per workspace basis
	foreach ($workspace in $workspaces) {
        write-host "****************************************************"
        write-host "Workspace:" $workspace.Name
        # We need to append the environment label to get the correct name of the workspace
        $workspaceName = $workspace.Name + $EnvLabel
        write-host "Workspace to deploy to: " $workspaceName
        $sourcePath = $basePBIPPath + "\" + $workspace.Name
        write-host "Folder to Deploy:" $sourcePath
               
        # Get the workspace ID
        write-host "Getting Workspace Id creating it if needed, for .. " $workspaceName
        $NewWorkspaceCall = "New-FabricWorkspace  -name " + $workspaceName + " -skipErrorIfExists"
        Write-Host "Newworkspace call:  " $NewWorkspaceCall
        $workspaceId = New-FabricWorkspace  -name $workspaceName -skipErrorIfExists
        write-host "Workspaceid:  " $workspaceId

        # Set the permission
        Write-Host "Setting default workspace permissions.."
        Set-FabricWorkspacePermissions -workspaceId $workspaceId -permissions $workspacePermissions

        #Deploy all reports in folder to workspace
        write-host "path we are deploying: " $sourcePath
        write-host "Workspace we are deploying to: " $workspaceName
        $NewFabricItemCall = "Import-FabricItems -workspaceId " + $workspaceId + " -path " + $sourcePath
        Write-Host "NewFabricItemCall: " $NewFabricItemCall
        Import-FabricItems -workspaceId "$workspaceId" -path "$sourcePath"

         write-host "****************************************************"
        
    }
    write-host "Done deploying PBIPs to workspaces"
}