<#
    .SYNOPSIS 
     Moves the most current Mosaic Director backup from production to staging for refresh
    .DESCRIPTION
     Runs via Windows Scheduler (can be called interactively) - will locate the latest
     Mosaic Director backup on MOSPSQL01A and copy it / overwrite in destination on MOSSSQL01A

     This prepares a current backup on CPS Staging for our weekly restore process.

     This is automated with no arguments.  Please modify script variables to adjust params.
     Yes - I trimmed pwd - make usre no pwds have tailing spaces (or leading)
     
#>
Param([Parameter(Mandatory=$true)] [string]$shareUser, [Parameter(Mandatory=$true)] [string]$shareUserPwd, [Parameter(Mandatory=$true)] [string]$sourceUNC,[Parameter(Mandatory=$true)] [string]$destUNC);

#quick input trim on strings
$shareUser = $shareUser.trim();
$shareUserPassword = $shareUserPwd.trim();
$sourceUNC = $sourceUNC.trim();
$destUNC = $destUNC.Trim();


################################################################
# Local globals : change if needed
################################################################
#$shareUser = "user@domain";
#$sharePassword = "password";
$debugPreference = "Continue"; # if you want debugging set to 'continue', disable with 'SilentlyContinue'
$debugHack = $true; # set this to false when testing in real world - seems to be an issue with test-path and network shares in development env (Windows PS ISE)
$echoOn = 1; # set to "0" to only event log; "1" to echo to console and event log
#source and destination directories - in this case dest is UNC
$sourceDriveLetter = "V";
$destinationDriveLetter = "U";
$sourceDirectory =   $sourceDriveLetter + ":\";

#$newFileName = "Director-latest-from-production.bak";

################################################################
# Do not change anything in this area!
################################################################

$eventLogName = "Database Refresh From Production";
$isAdmin = $false;
$logTime = Get-Date -Format "MM-dd-yyyy_hh-mm-ss";
$logFile = '{0}\deploy-{1}.log' -f $sourceDirectory, $logTime;
#LOCAL FUNCTIONS ############################
# - need functions for writing logs in a standard way
function LogInfo{
    Param([String]$message, [Boolean]$echo);
    Write-EventLog -LogName $eventLogName -Source $eventLogName -Message $message -EventId 0 -EntryType information;
    #$message | Out-File -LiteralPath $logFile -Append
    if($echo){
        Write-Host -ForegroundColor Green $message;
    }
}
function LogWarn{
    Param([String]$message, [Boolean]$echo);
    Write-EventLog -LogName $eventLogName -Source $eventLogName -Message $message -EventId 0 -EntryType warning; 
    #$message | Out-File -LiteralPath $logFile -Append
    if($echo){
        Write-Host -ForegroundColor DarkYellow $message;
    }
}
function LogError{
    Param([String]$message, [Boolean]$echo);
    Write-EventLog -LogName $eventLogName -Source $eventLogName -Message $message -EventId 0 -EntryType error; 
    #$message | Out-File -LiteralPath $logFile -Append
    if($echo){
        Write-Host -ForegroundColor Red $message;
    }
}
# duplicate cmd shell's 'pause' in PS
function Pause {
    $Message = "Press any key to continue . . . ";
    if ((Test-Path variable:psISE) -and $psISE) {
        $Shell = New-Object -ComObject "WScript.Shell";
        $Button = $Shell.Popup("Click OK to continue.", 0, "Script Paused", 0);
    }
    else {     
        Write-Host -NoNewline $Message;
        [void][System.Console]::ReadKey($true);
        Write-Host;
    }
}

#check if admin 
function AmIAdmin {
    $user = [Security.Principal.WindowsIdentity]::GetCurrent();
    return (New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator);
}

function TestDirectoryExists {
    Param([String]$directory);
    $isGood = Test-Path ($directory) -pathType container;
    Write-Debug ("IsValidPath: " + $isGood);
    return $isGood
}
function TestFileExists {
    Param([String]$file);
    $isGood = Test-Path ($file) -pathType Leaf;
    Write-Debug ("IsValidFile: " + $isGood);
    return $isGood
}
function MapDrive {
Param([String]$drive, [String]$uncPath, [String]$user, [String]$password, [String]$description);
    #PS 2 doesnt support PSDrive properly
    if($PSVersionTable.psversion.major -lt 3){
        $net = new-object -ComObject WScript.Network;
        $net.MapNetworkDrive(($drive + ":"), $uncPath, $true, $user, $password);
        Write-Debug ("Mapped drive (pre-PS3): " + $drive);
    } else{
        $pwd = $password | ConvertTo-SecureString -AsPlainText -Force;
        $creds = New-Object System.Management.Automation.PsCredential($user,$pwd);
        New-PSDrive -Name $drive -PSProvider FileSystem -Root $uncPath -Credential $creds -Persist;
       Write-Debug ("Mapped drive (PS3+): " + $drive);
    }
}
#END FUNCTIONS ############################

#Check a few things before we begin
if(!(AmIAdmin)){
    LogError "You must run this script as administrator or a member of the administrators group! Exiting script..." $true;
    Exit;
}

try{
#perform the copy
#TODO here
if(!TestDirectoryExists "V"){
    MapDrive "V" "\\serversource\c$" $shareUser $sharePassword "Map source directory"
}
if(!TestDirectoryExists "U"){
    MapDrive "U" "\\serverdest\c$" $shareUser $sharePassword "Map destination directory"
}
$fileToMove = Get-ChildItem  $sourceDirectory | sort LastWriteTime | Select-Object -Last 1 -Property Name;
LogInfo "Copying $fileToMove from $sourceDirectory to $destinationDirectory" $true;
#Copy-Item ($sourceDirectory + "\" + $fileToMove) ($destinationDirectory + "\" + $newFileName);
LogInfo "Copy successful" $true;
} catch {
    LogError "An error of type $($_.Exception.GetType().FullName) occurred.  The error message is $($_.Exception.Message)" $true;
}
#TODO - check the destination file for name and date time to confirm it copied over