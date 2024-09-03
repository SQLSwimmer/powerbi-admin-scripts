# build out the drop directory
$dropDirectory = $env:Build_ArtifactStagingDirectory + "\drop\"
write-host "working directory: " $dropDirectory

# build out the source directory 
$sourceDirectory = $env:Build_Repository_LocalPath + "\" 
write-host "source directory:" $sourceDirectory

# get the commit message, it tells us what workspace environment to deploy to
$commitMessage = $env:Build_SourceVersionMessage
Write-Host "Commit message:  " $commitMessage

# now write the commit message to file in drop folder
# Create the directory if it doesn't exist
Write-Host "Creating Drop directory if it does not already exist.."
New-Item -Path $dropDirectory -ItemType Directory -Force

# Write the commit message to the COMMIT file
$commitMessageFilePath = "$dropDirectory/COMMIT"
Set-Content -Path $commitMessageFilePath -Value $commitMessage

# Run the git diff command and get the output
$gitDiffOutput = git diff --name-only HEAD^ HEAD --diff-filter=d

# check for just deleted files, we don't need to do anything if all files are deleted
if (-not $gitDiffOutput ) {
    write-host "Only operation is to delete these files"
    $gitDiffOutput = git diff --name-only HEAD^ HEAD --diff-filter=D
    $gitDiffOutput 

    # Now set Publish Artifact variable so we skip the publish step
    Write-Host "##vso[task.setvariable variable=PublishArtifact;]$false"
    Exit
}

# Split the output into individual file paths
$filePaths = $gitDiffOutput -split "`n"

# List files 
$filePaths

# Convert to folder paths
$folderPaths = @()

# Loop through each item and get the path
foreach ($filePath in $filePaths) {
    if ($filePath) {
        # Get the directory of the file path
        $folderPath = [System.IO.Path]::GetDirectoryName($filePath)

        # if folder path not a pbip payload directory, there is no special processing, we just include it
        if (-not($folderPath.Contains(".SemanticModel") -or $folderPath.Contains(".Report")) -and -not $folderPaths.Contains($folderPath)) {
            write-host "folderPath not a pbip payload: " $folderPath
            $folderPaths += $folderPath
            write-host "Going to next file"
            Break
        }

        # now get the relative Power BI directory, because that's all we care about
        # Depending on where the pbip directories start, you may need to include/exclude \s in the statement below
        $pathComponents = $folderPath -split "\\"

        # Check if there are at least 3 levels in the path
        if ($pathComponents.Length -ge 4) {
            # Get the first three levels and join them to form the full path to the third level directory
            $pbipDirectory = ($pathComponents[0..3] -join "\")
            Write-host "The full path to the 3rd level directory is: $pbipDirectory"
        } else {
            Write-Host "The specified path does not have 3 levels."
        }


        # Add the pbip folder path to the array if it's not already included
        if ($folderPath -and -not $folderPaths.Contains($pbipDirectory)) {
            $folderPaths += $pbipDirectory
        }
        # Check for pbip sister folder, we want both .semanticmodel and .report folders
        if ($pbipDirectory.Contains(".SemanticModel")) {
            write-host "Current folder is .SemanticModel"
            $sisterFolder = $pbipDirectory.Replace(".SemanticModel",".Report")
        }
        elseif ($pbipDirectory.Contains(".Report")) {
            write-host "Current folder is .Report"
            $sisterFolder = $pbipDirectory.Replace(".Report", ".SemanticModel")
        }
        else {
            # it's not a PBIP folder
            write-host "It's not a PBIP folder"
        }

        #Now add it if it doesn't already exist 
        if ($sisterFolder -and -not $folderPaths.Contains($sisterFolder)) {
            # make sure the source folder exists before we add it
            $sourceSisterFolder = $sourceDirectory + $sisterFolder
            if (Test-Path -Path $sourceSisterFolder -PathType Container) {
                write-host "Sister source folder exists, adding: " $sisterFolder
                $folderPaths += $sisterFolder
            }
            else {
                write-host "Sister source folder does not exist"
            }
        }
    }
}
write-host "Unique folder names.."
$folderPaths

    foreach ($folder in $folderPaths) {
        # Build the path to drop the file
        $folderToCopy = $sourceDirectory + $folder
        write-host "folderToCopy" $folderToCopy 
        $destination = $dropDirectory + $folder
        write-host "destinationfolder: " $destination

        # Ensure the destination directory exists
        $destinationDirectory = $destination
        if (-Not (Test-Path -Path $destinationDirectory)) {
            write-host "Creating directory: " $destinationDirectory
            New-Item -ItemType Directory -Path $destinationDirectory -Force
        }

        $source = $folderToCopy + "\*"
        # Copy folder and contents
        $copyCommand = "copy-item -Path $source-Destination $destinationDirectory -recurse -force"
        write-host "Copy Command: " $copyCommand
        copy-item -Path $source -Destination $destinationDirectory -recurse -force
    }

# Now set Publish Artifact variable so run the publish step
Write-Host "##vso[task.setvariable variable=PublishArtifact;]$true"

# Following line is for visibility into what has been copied, it can be commented out without ill effect
get-childitem -Path $dropDirectory -Recurse
