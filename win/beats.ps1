 param (
    [Parameter(Mandatory=$true)][string]$action,
    [Parameter(Mandatory=$true)][string]$beats,
    [Parameter(Mandatory=$true)][string]$url
 )
 function install()
 {
     Write-Output "Install"
     #Create Install Dir if doesn't exist.
     mkdir -force $InstallDir
     #Split beats argument into array
     $BeatsArray = $beats.Split("-")
     #Iterate over beats in array and install one at a time
     foreach ($beat in $BeatsArray) {
         Write-Output "Installing: " $beat
         #Unzip to install dir
         expand-archive -path ".\packages\$beat.zip" -destinationpath $InstallDir -Force
         #Find the install path for the beat (versions etc make it hard to hard code)
         $dirPath = Get-ChildItem $InstallDir -Recurse | Where-Object { $_.PSIsContainer -and $_.Name.StartsWith($beat)}
         $beatPath = $InstallDir + "\" + $dirPath
         #Copy the base config file
         Copy-Item -Force ..\configs\$beat.yml $beatPath
         #Replace the logstash URL with the one provided at runtime
         ((Get-Content -path $beatPath\$beat.yml -Raw) -replace '%LOGSTASH_HOST%', $url) | Set-Content -Path $beatPath\$beat.yml
         #Install the beat as a service using the provided install service powershell
         $serviceInstaller = $beatPath + "\install-service-" + $beat+ ".ps1"
         invoke-expression -Command $serviceInstaller
     }
 }
 
 function uninstall()
 {
     Write-Output "Uninstall"
     $BeatsArray = $beats.Split("-")
     #Iterate over beats in array and uninstall one at a time
     foreach ($beat in $BeatsArray) {
         #Find the install path for the beat (versions etc make it hard to hard code)
         $dirPath = Get-ChildItem $InstallDir -Recurse | Where-Object { $_.PSIsContainer -and $_.Name.StartsWith($beat)}
         $beatPath = $InstallDir + "\" + $dirPath
         #Uninstall the beat as a service using the provided uninstall service powershell
         $serviceUninstaller = $beatPath + "\uninstall-service-" + $beat+ ".ps1"
         invoke-expression -Command $serviceUninstaller
         #Delete files
         Write-Output $beatPath
         del -recurse $beatPath
         #Remove-Item –path "$beatPath" –recurse 
     }
 }


Write-Output "Start"
$InstallDir = "C:\beats"

if($action.Equals("install")) {
    Write-Output "Calling install"
    install
}
if ($action.Equals("uninstall")) {
    Write-Output "Calling uninstall"
    uninstall
}

