#*----------------------------------------------------------------------------------------------------------------------------
#  Filename       : mssql_AutoRestoreMultipleDatabasesInOneGo.ps1
#  Purpose        : Script to restore all databases from a backup folder on to a SQL Server.
#  Schedule       : Ad-Hoc
#  Date           : 25-September-2014
#  Author         : www.sherbaz.com/Sherbaz Mohamed
#  Version        : 1
#  Modded from original Brian P  -add logging, fix possible bugs, some console output, option to turn norecovery on/off
#
#  Important --arks:    
#  INPUT          : $path = Backup folder, $sqlserver = Destination SQL Server instance name, $datafolder = datafilelocation, $logfolder = logfilelocation, $norecovery  =true/false
#  VARIABLE       : NONE
#  PARENT         : NONE
#  CHILD          : NONE
#  NOTE           : The database path will be retrieved from SQL Server database settings
#---------------------------------------------------------------------------------------------------------------------------*/
# Usage:
# ./mssql_AutoRestoreMultipleDatabasesInOneGo.ps1 "E:\database_Backup_Source_Folder\" "hostname\instancename" "destinationdatafolderpath" "destinationtransactionlogfolderpath" $false
# 
Param([Parameter(Mandatory=$true)] [string]$path, [Parameter(Mandatory=$true)] [string]$sqlserver, [Parameter(Mandatory=$true)] [string]$datafolder,[Parameter(Mandatory=$true)] [string]$logfolder,[Parameter(Mandatory=$true)] [string]$norecovery);

#quick input trim on strings
$path = $path.trim();
$sqlserver = $sqlserver.trim();
$datafolder = $datafolder.trim();
$logfolder = $logfolder.Trim();


# duplicate cmd shell's 'pause' in PS
Function Pause {
    $Message = "Ready to go.  Press any key to continue . . . ";
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

#load needed assemblies; it errored on me otherwise - apparently this is deprecated, but it works - use reflection:
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") | out-null
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMOExtended')  | out-null
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SQLWMIManagement')  | out-null

$beforeCount = (Get-ChildItem -Path $path -File | Measure-Object).Count;

#logs
$logSkipped = ((Split-Path $MyInvocation.MyCommand.Path) + "\databases-skipped.txt");
$logRestored = ((Split-Path $MyInvocation.MyCommand.Path) + "\databases-restored.txt");


#--COMMENT NEXT 2 LINES - if you do not want to write over the log files after every script execution
New-Item -path $logRestored -itemtype file -force | out-null
New-Item -path $logSkipped -itemtype file -force | out-null


Write-Host "";
Write-Host "";
Write-Host "1. Creating log files...";
Write-Host "2. Databases to restore (counting .bak files):"  $beforeCount;
Write-Host "3. NoRecovery setting (false = 'with recovery'):"  $norecovery;
Write-Host "------";

#--COMMENT NEXT LINE - if not run interactive
Pause;

Write-Host "Alrighty then!  Starting the restore(s)...";

$actualCount = 0;

foreach($bkpfile in Get-ChildItem $path "*.bak" | Select-Object basename) {
     $bkpfile = $bkpfile.BaseName
     $server = New-Object Microsoft.SqlServer.Management.Smo.Server($sqlserver)
     $restore = New-Object Microsoft.SqlServer.Management.Smo.Restore

     $bkfilepath = ($path + "\"+ $bkpfile + ".bak");

     $restore.Devices.AddDevice($bkfilepath, [Microsoft.SqlServer.Management.Smo.DeviceType]::File)
     $header = $restore.ReadBackupHeader($server)

     if($header.Rows.Count -eq 1) {
        $dbname = $header.Rows[0]["DatabaseName"];

        # Connect to the specified instance
        $srv = new-object ('Microsoft.SqlServer.Management.Smo.Server') $sqlserver

        # Get the default file and log locations
        # (If DefaultFile and DefaultLog are empty, use the MasterDBPath and MasterDBLogPath values)

        if(!$datafolder){
            $fileloc = $srv.Settings.DefaultFile
        } else { 
            $fileloc = $datafolder
        }

        if(!$logfolder){
            $logloc = $logloc = $srv.Settings.DefaultLog
        } else { 
            $logloc = $logfolder
        }

        if ($fileloc.Length -eq 0) {
            $fileloc = $srv.Information.MasterDBPath
            }

        if ($logloc.Length -eq 0) {
            $logloc = $srv.Information.MasterDBLogPath
            }

        # Identify the backup file to use, and the name of the database copy to create
        $bckfile = $bkfilepath
        $dbname = $dbname


        # Build the physical file names for the database copy (BJP - this seemed a bit wacky and not needed for us; this tests fine)
        #if($fileloc -ne $logloc)
        #{
        #            $dbfile = $fileloc + '\Data\'+ $dbname + '.mdf'
        #            $logfile = $logloc + '\Log\'+ $dbname + '.ldf'
        #}
        #else
        #{
        #            $dbfile = $fileloc + '\'+ $dbname + '.mdf'
        #            $logfile = $logloc + '\'+ $dbname + '.ldf'
        #}

        $dbfile = $fileloc + '\'+ $dbname + '.mdf'
        $logfile = $logloc + '\'+ $dbname + '.ldf'


        # Use the backup file name to create the backup device
        $bdi = new-object ('Microsoft.SqlServer.Management.Smo.BackupDeviceItem') ($bckfile, 'File')

        # Create the new restore object, set the database name and add the backup device
        $rs = new-object('Microsoft.SqlServer.Management.Smo.Restore')
        $rs.Database = $dbname
        $rs.Devices.Add($bdi)

        # Get the file list info from the backup file

        $fl = $rs.ReadFileList($srv)
        $rfl = @()
        foreach ($fil in $fl) {
            $rsfile = new-object('Microsoft.SqlServer.Management.Smo.RelocateFile')
            $rsfile.LogicalFileName = $fil.LogicalName

            if ($fil.Type -eq 'D') {
                $rsfile.PhysicalFileName = $dbfile

            } else {
                $rsfile.PhysicalFileName = $logfile
                }
            $rfl += $rsfile
        }

        #Restore the database
        if($norecovery -eq $true){
            Restore-SqlDatabase -ServerInstance $sqlserver -Database $dbname -BackupFile $bkfilepath -RelocateFile $rfl -NoRecovery
        }else{
            Restore-SqlDatabase -ServerInstance $sqlserver -Database $dbname -BackupFile $bkfilepath -RelocateFile $rfl
        }
        #Add-Content $logRestored ($dbname + "'n");
        Add-Content $logRestored ($dbname);
        $actualCount++;

     } else{
        Write-Host "This backup has more than one header - something isn't right...skipping";
        #Add-Content $logSkipped ($bkpfile + "'n");
        Add-Content $logSkipped ($bkpfile);
 
     }
}

Write-Host "###############################################################";
Write-Host "Database Count before (counting bak files)" $beforeCount;
Write-Host "Databases actually restored:" $actualCount;
Write-Host "";
Write-Host "Databases skipped and restored located in local log files. Please check.";
Write-Host "###############################################################";
Write-Host "";
Write-Host "DONE...";