<#   
This script compress all .bak files {sql backups} recursively from location specified
#> 
 
#### 7 zip env variable I got it from the below link ; gen alias as well 
#### http://mats.gardstad.se/matscodemix/2009/02/05/calling-7-zip-from-powershell/  
# Alias for 7-zip 
if (-not (test-path "$env:ProgramFiles\7-Zip\7z.exe")) {throw "$env:ProgramFiles\7-Zip\7z.exe needed"} 
set-alias sz "$env:ProgramFiles\7-Zip\7z.exe" 
 
###############Change these as needed

$sourceFilePath = "C:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Backup" 
$backupLocation = Get-ChildItem -Recurse -Path $sourceFilePath | Where-Object { $_.Extension -eq ".bak" -and ! $_.PSIsContainer } 
#logs
$logSkipped = ((Split-Path $MyInvocation.MyCommand.Path) + "\skipped.txt");
$logProcessed = ((Split-Path $MyInvocation.MyCommand.Path) + "\processed.txt");
#--COMMENT NEXT 2 LINES - if you do not want to write over the log files after every script execution
New-Item -path $logProcessed -itemtype file -force | out-null
New-Item -path $logSkipped -itemtype file -force | out-null
################
 
foreach ($file in $backupLocation) { 
                    $name = $file.name 
                    $directory = $file.DirectoryName 
                    #$zipfile = $name.Replace(".bak",".zip") 
                    $zipfile = ($name -ireplace ".bak",".zip")
                    #zipformat - with AES using 7z
                    sz a -tzip "$directory\$zipfile" "$directory\$name" -mem=AES256  -pmi83pBATt6AmEDGQRB3S
                    #sz a -tzip "$directory\$zipfile" "$directory\$name" # no AES zip version
                    if ($LASTEXITCODE -ne 0) {
                        Add-Content $logSkipped ("$directory\$zipfile --> $directory\$name");
                    } else{
                        Add-Content $logProcessed ("$directory\$zipfile --> $directory\$name");
                    }
                } 
 
########### END OF SCRIPT ########## 