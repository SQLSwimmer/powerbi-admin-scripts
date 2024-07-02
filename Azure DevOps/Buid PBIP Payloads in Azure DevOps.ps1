# Write your PowerShell commands here.

$dropDirectory = $env:Build_ArtifactStagingDirectory + "\drop\"
write-host "working directory: " $dropDirectory

$sourceDirectory = $env:Build_Repository_LocalPath + "\" 
write-host "source directory:" $sourceDirectory


$files = git diff --name-only HEAD^ HEAD
write-host "list of changed files"
$files
write-host "*********************************************************************"

    foreach ($file in $files) {
        # Build the path to drop the file
        $fileToCopy = $sourceDirectory + $file.Replace("/", "\")
        write-host "fileToCopy" $fileToCopy 
        $destination = $dropDirectory + $file.Replace("/", "\")

        # Get the relative path so we can copy all the files needed for the pbip payload
        $relativePath = $destination.Substring($dropDirectory.Length).TrimStart([System.IO.Path]::DirectorySeparatorChar)
        Write-Host "Relative Path: " $relativePath


        # Ensure the destination directory exists
        $destinationDirectory = Split-Path -Parent $destination
        if (-Not (Test-Path -Path $destinationDirectory)) {
            write-host "Creating directory: " $destinationDirectory
            New-Item -ItemType Directory -Path $destinationDirectory -Force
        }

        # Copy file
        If ($fileToCopy -like "*.SemanticModel*" -or $destinationDirectory -like "*.Report*"){
            # we need to get all the files in the directory for the pbip payload
            $source = (split-path -parent $fileToCopy) + "\*"
            write-host "payload directory: " $source

            $copyCommand = "copy-item -Path $source -Destination $destinationDirectory -recurse -force"
            write-host "Copy Command: " $copyCommand
            copy-item -Path $source -Destination $destinationDirectory -recurse -force

            #We also need to check if there is a corresponding .semanticmodel or .report folder, if there is, we have to copy that too
            if ($destinationDirectory  -like "*.SemanticModel*") {
                # if the .Report folder exists, we have to copy that too
                if (Test-Path -Path (split-path -parent $fileToCopy).Replace(".SemanticModel", ".Report")) {
                    #Build the .Report path
                    $source = (split-path -parent $fileToCopy).Replace(".SemanticModel", ".Report") + "\*"
                    $destination = $destinationDirectory.Replace(".SemanticModel", ".Report")
                    write-host "We have to copy the .Report folder too: "
                    $copyCommand = "copy-item -Path $source -Destination $destination -recurse -force"
                    write-host "Copy Command: " $copyCommand
                    copy-item -Path $source -Destination $destination -recurse -force
                }
            }
            else {
                # if the .Semantic folder exists, we have to copy that too
                if ($destinationDirectory -like "*.Report*") {
                    #Build the .SemanticModel path
                    if (Test-Path -Path (split-path -parent $fileToCopy).Replace(".Report", ".SemanticModel")) {
                        #Build the .Report path
                        $source = (split-path -parent $fileToCopy).Replace(".Report", ".SemanticModel") + "\*"
                        $destination = $destinationDirectory.Replace(".Report", ".SemanticModel")
                        write-host "We have to copy the .SemanticModel folder too: "
                        $copyCommand = "copy-item -Path $source -Destination $destination -recurse -force"
                        write-host "Copy Command: " $copyCommand
                        copy-item -Path $source -Destination $destination -recurse -force
                    }
                }
                
            }
        }
        else {
            $source = $fileToCopy
            $copyCommand = "copy-item -Path $source -Destination $destination"
            write-host "Copy Command: " $copyCommand
            copy-item -Path $source -Destination $destination -recurse
            write-host "*********************************************************************"
        }
    }

write-host "Done copying changed files and payload, contents of drop folder:"
get-childitem -Path $dropDirectory -recurse