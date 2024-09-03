# Get the PowerShell Path from the variable Group
#$PSPath = "PS Scripts"
$PSPath = "$env:PowerShellScriptPath"

#build out the drop directory
$dropDirectory = $env:Build_ArtifactStagingDirectory + "\drop\"
write-host "working directory: " $dropDirectory

#build out the PowerShell source directory 
$sourceDirectory = $env:Build_Repository_LocalPath + "\$PSPath" 
write-host "source directory:" $sourceDirectory

# Now copy PS scripts folder to drop location
# create the path if it doesn't exist
write-host "folderToCopy" $sourceDirectory
$destination = $dropDirectory + $PSPath
write-host "destinationfolder: " $destination

# Ensure the destination directory exists
$destinationDirectory = $destination
if (-Not (Test-Path -Path $destinationDirectory)) {
    write-host "Creating directory: " $destinationDirectory
    New-Item -ItemType Directory -Path $destinationDirectory -Force
}

$source = $sourceDirectory + "\*"

# Copy folder and contents
$copyCommand = "copy-item -Path $source-Destination $destinationDirectory -recurse -force"
write-host "Copy Command: " $copyCommand
copy-item -Path $source -Destination $destinationDirectory -recurse -force


# Now set Publish Artifact variable so run the publish step
#Write-Host "##vso[task.setvariable variable=PublishArtifact;]$true"

# Following line is for visibility into what has been copied, it can be commented out without ill effect
get-childitem -Path $dropDirectory -Recurse
