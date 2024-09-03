Write-Host "Starting.."
$artifact = "$env:System_ArtifactsDirectory\$env:Release_PrimaryArtifactSourceAlias\drop"
write-host "Artifact: " $artifact


# Check if the build artifact exists and set variable accordingly
if (-Not (Test-Path -Path $artifact)) {
    # Set Publish Artifact variable so we skip the publish step
    write-Host "No build artifacts, nothing to release"
    Write-Host "##vso[task.setvariable variable=PublishArtifact;]$false"
}
else {
    # Now set Publish Artifact variable so we continue with the release
    write-host "We have build artifacts, continuing with release"
    Write-Host "##vso[task.setvariable variable=PublishArtifact;]$true"

}
