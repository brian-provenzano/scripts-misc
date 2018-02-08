#for IIS:\ usage
import-module webadministration

#Path to Mosaic Install Files ending in a slash \
$mosaicfiles = "D:\Hosted Mosaic Server Update\Web Tier New District Setup\"

#Path to List of Mosaic Districts
$mosaicclients = "D:\scripts\currentmosaicdbs.txt"

# String to find in web.config files to replace with District Name
$templateNCESFindString = "[NCES]";

# Create Website for each Application
function CreateWebSite($districtName, $applicationType, $applicationPoolName)
{
    # Setup IIS folder for creating sub-directory and copying files
    $iisFolder = "D:\wwwroot\"
    
    $applicationName = $districtName + $applicationType
    
    # Create directory if it doesn't exist
    $applicationFolder = $iisFolder + $applicationName
    if ((Test-Path -path $applicationFolder) -eq $false) { New-Item $applicationFolder -type directory } 
    else
    {write-Host $applicationFolder "Folder already exists terminating script."
    Exit 
    } 
    Write-Host "The" $applicationFolder "folder has been created successfully."

    # Copy files into the new directories
    $rootCopy = $mosaicfiles + $applicationType + "\*"
    Copy-Item $rootCopy $applicationFolder -recurse -Force
    Write-Host "The" $applicationType "files have been copied successfully."
            
    #Create Web Application
    $iisApplication = "IIS:\Sites\Default Web Site\" + $applicationName    
    New-Item $iisApplication -physicalPath $applicationFolder -type Application -force
    Write-Host "The" $applicationName "Web Application has been created successfully."
    
    #Moving the Site to the correct app pools
    Set-ItemProperty -path $iisApplication -name applicationPool -value $applicationPoolName
    Write-Host "The" $applicationName "Web Application has been moved to the" $applicationPoolName

    #Update Connection Strings in web.config to correct NCES 
    #PSV4 
    [xml]$newConfig = $(Get-Content ($applicationFolder + "\" + "web.config")).Replace($templateNCESFindString,$districtName);
    #PSV2
	#[xml]$newConfig = $([string]$(Get-Content ($applicationFolder + "\" + "web.config"))).Replace($templateNCESFindString,$districtName);
    $newConfig.Save($applicationFolder + "\" + "web.config");
    Write-Host "The Initial Catalog value in the" $applicationName "Web.config has been updated to the NCES#"$districtName 
          
    # Write blank line for formatting
    Write-Host "" 
}

cls


Foreach ($districtName in get-content $mosaicclients) {
CreateWebSite -districtName $districtName -applicationType "Mosaic" -applicationPoolName "MosaicOne"
CreateWebSite -districtName $districtName -applicationType "MosaicPOS" -applicationPoolName "POSOne"
}

