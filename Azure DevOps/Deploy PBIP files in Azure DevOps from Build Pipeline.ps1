write-host "Starting.."

# ********************************** Build Working Directory and paths ******************************************
#Get working directory
$workingDirectory = $env:System_ArtifactsDirectory + "\drop\$(PBIRootpath)" 
write-host "Working directory:  " $workingDirectory

#Build the base path 
$basePath = $workingDirectory 
write-host "basePath:  " $basePath


#Get dataset workspace name indicator
$dataworkspaceIndicator = "$(DatasetWorkspaceNameIndicator)"
write-host "Dataset Workspace Indicator:  " $dataworkspaceIndicator

#Get Environment label
$EnvLabel = "$(EnvironmentLabel)"
write-host "Environment Label:" $EnvLabel


#Get dataset and report workpace/folder names
$reportWorkpaceBase = "$(ReportsCodeWorkingDirectory)" 
write-host "Report workspace base: " $reportWorkpaceBase
$datasetWorkspaceBase = "$(DatasetsCodeWorkingDirectory)"  #+ "$(dataworkspaceIndicator)"+ "$(EnvironmentLabel)"
write-host "Dataset workspace base: " $datasetWorkspaceBase



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
# Folders translate to deploy type and workspaces, we do the deploy type first
$deployTypes= Get-ChildItem  -Path $basePath | Where-Object { $_.PSIsContainer }
foreach ($deployType in $deployTypes)
{
    if ($deployTypes.count -eq 0) {
        Write-Host "No Payload folders found"
    }
    else {
        if ($deployType.Name -eq "$(DatasetsCodeWorkingDirectory)") { 
            $sourcePath = $basePath + "\" + "$(DatasetsCodeWorkingDirectory)"
        }
        else { 
            $sourcePath = $basePath + "\" + "$(ReportsCodeWorkingDirectory)"
        }
    }

    write-host "sourcePath: " $sourcePath

    # Now we loop through the workspaces in the deploy type
    $workspaces = get-childitem -Path $sourcePath | where-object {$_.PSIsContainer}

    # We want to deploy on a per workspace basis
    foreach ($workspace in $workspaces) {
        write-host "****************************************************"
        write-host "Workspace:" $workspace.Name
        # We need to append the environment label to get the correct name of the workspace
        $workspaceName = $workspace.Name + $EnvLabel
        write-host "Workspace to deploy to: " $workspaceName
        $sourcePath = $sourcePath + "\" + $workspace.Name
        write-host "Folder to Deploy:" $sourcePath
               
        # Get the workspace ID
        write-host "Getting Workspace Id creating it if needed, for .. " $workspaceName
        $NewWorkspaceCall = "New-FabricWorkspace  -name " + $workspaceName + " -skipErrorIfExists"
        Write-Host "Newworkspace call:  " $NewWorkspaceCall
        $workspaceId = New-FabricWorkspace  -name $workspaceName -skipErrorIfExists
        write-host "Workspaceid:" $workspaceId

        #Deploy all reports in folder to workspace
        write-host "path we are deploying: " $sourcePath
        $NewFabricItemCall = "Import-FabricItems -workspaceId " + $workspaceId + " -path " + $sourcePath
        Write-Host "NewFabricItemCall: " $NewFabricItemCall
        Import-FabricItems -workspaceId "$workspaceId" -path "$sourcePath"

         write-host "****************************************************"
        
    }
}
