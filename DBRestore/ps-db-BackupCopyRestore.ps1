<#
    Database migration (Backup, copy and restoration all user DBs)
    Version : 1.0
    Author : Ashok Sagar Bazar
    Environment : Windows 2008R2
    Powershell Version : 3.0

#>

Clear-host
#### PACKAGES/MODULES #####
#############################################################

#Import-Module -Name 'SQLPS' -DisableNameChecking
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO")| out-null
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SmoExtended")| out-null
#Import-Module -Name SqlServer
#asnp SqlServer* -ea 0
#Set-ExecutionPolicy -ExecutionPolicy Unrestricted 
#$credentials1 = Get-Credential -Credential ""
$startTime = Get-Date


#### SOURCE SERVER DETAILS #####
#############################################################

$sourceServer = "WIN-U9ESO6DOFR2\Primarysrv"
#$sourceServer = Read-Host "Enter source Instance Name"
$sourceObj = New-Object ('Microsoft.SqlServer.Management.Smo.Server') $sourceServer
#$sourceObj.Settings
$sourceBackupPath = $sourceObj.Settings.BackupDirectory + "\"
$sourceHostname = $sourceObj.NetName
$sourceRemotePath =  "\\" + $sourceHostname + "\" + $sourceBackupPath
$sourceRemotePath =$sourceRemotePath.Replace(':','$')
$sourceRemotePath = $sourceRemotePath + "SourceBackupFolder\"
Invoke-Command { if(-not $sourceRemotePath.fullname ){ MKDIR $sourceRemotePath -ErrorAction SilentlyContinue } }
#$sourceRemotePath
$i = 0
$j = 0

#### DESTINATION SERVER DETAILS #####
#############################################################

#$destiServer = Read-Host "Enter destination Instance Name"
$destiServer = "WIN-U9ESO6DOFR2\secondarySRV"
$destObj = New-Object ('Microsoft.SqlServer.Management.Smo.Server') $destiServer
## Must check these values from assembly
$destBackupPath = $destObj.Settings.BackupDirectory + "\"
$DestiDataPath = $destObj.MasterDBPath
#$DestiDataPath
$DestiLogPath = $destObj.MasterDBLogPath
#$DestiLogPath
$dbRestoreFile2 = $destObj.MasterDBPath
$destiHostname = $destObj.NetName
$destiRemotePath =  "\\" + $destiHostname + "\" + $destBackupPath
$destiRemotePath = $destiRemotePath.Replace(':','$')
$destiRemotePath = $destiRemotePath + "DestinationBackupFolder\"
Invoke-Command { if(-not $destiRemotePath.fullname ){ MKDIR $destiRemotePath -ErrorAction SilentlyContinue } }
#$destiRemotePath

## Remove files from source path before start backup
Remove-Item -Path $sourceRemotePath* -Include *.bak -ErrorAction SilentlyContinue;

#### DATABASE DETAILS #####
#############################################################

$dbs = $sourceObj.Databases | where {$_.IsSystemObject -eq $false }
#$dbs.name
$InputLines = $dbs.count
#$InputLines
$count = 0

#### BACKUP USER DBS / FILTER DBS #####
#############################################################

foreach ($db in $dbs) 
{
     $count += 1
     Write-Progress -Activity "$count. $db  Backup in progress" -percentComplete (($count) / $InputLines * 100)
     try
     {        
        ###########################################
        ## DBS SELECTIONS / FILTER PART
        ###########################################
        
        #if($db.Name -ne "sqladmin" -and $db.name -ne "ClientAddress")  ## Filter the DBs
        if($db.IsSystemObject -eq $false -and $db.status -ne 'OFFLINE')
        #if($db.name -eq 'LogTest') ## Selected DBs
        {   
        
        $dbname = $db.Name
        $dt = get-date -format yyyyMMdd_HHmmss #We use this to create a file name based on the timestamp                 
        $dbBackup = new-object ("Microsoft.SqlServer.Management.Smo.Backup")
        $dbBackup.Action = "Database"
        $dbBackup.Database = $dbname
        $dbbackup.compressionOption = 1
        $dbbackup.CopyOnly = 1
        $dbbackup.PercentCompleteNotification = 1
        $dbbackup.PercentComplete
        $dbBackup.Devices.AddDevice($sourceRemotePath + $dbname + "_FULL_" + $dt + ".bak", "File")           
        $dbBackup.SqlBackup($sourceObj) 
        write-host "BACKUP JOB>> " $db -ForegroundColor green
       
        }  
     }
     catch 
     { 
        $err = $_.Exception
        write-host $err.Message -ForegroundColor Magenta
         
        while( $err.InnerException ) 
        {
            $err = $err.InnerException
            write-host $err.Message -ForegroundColor yellow
        }
        
     }
}


#### COPY ALL BACKUPS WHICH ARE LAST PERFROMED #####
#############################################################

$EndTime = get-date
$duration = (NEW-TIMESPAN –Start $startTime –End $EndTime).Seconds

Remove-Item -Path $destiRemotePath* -Include *.bak -ErrorAction SilentlyContinue;
 
$Files = Get-ChildItem -path $sourceRemotePath* -Include *.bak


#|Where-Object {$_.lastwritetime -gt (get-date).AddSeconds(-$duration)}
foreach ($file in $files)
{
    $i += 1
    write-Progress -Activity "$i. Copying in-progress" -PercentComplete ($i / $files.count * 100)

    copy-Item $File $destiRemotePath -Force

    write-host "COPY JOB >> " $file.Name -ForegroundColor green
   
} 

#### RESTORE DATABASE ON RECENT BACKUPS #####
#############################################################

$dbs2 = $sourceObj.Databases | where {$_.IsSystemObject -eq $false }
#$dbs2.name
$InputLines2 = $dbs2.count
#$InputLines2
$count2 = 0                                                                                                                                                                                                                  
foreach ($db2 in $dbs2) 
{
     $count2 += 1
     Write-Progress -Activity "$count2. $db2  Restore in progress" -percentComplete (($count2) / $InputLines2 * 100)
     try
     {  
        #if($db.Name -ne "sqladmin" -and $db.name -ne "ClientAddress")  ## Filter the DBs
        if($db2.IsSystemObject -eq $false -and $db2.status -ne 'OFFLINE')      
        #if($db2.name -eq 'LogTest') ## Selected DBs
        {   
                
        $dbmatch = "*" + $db2.name + '*'
        #$dbmatch
        #$db2.name       
        
        $Files2 = Get-ChildItem -path $destiRemotePath* -Include *.bak | where {$_.name -like $dbmatch}      
        $bckfile = $Files2.FullName
        $dbname = $db2.name
        $backupDevice = New-Object ("Microsoft.SqlServer.Management.Smo.BackupDeviceItem") ($bckfile, "File")
        $dbrestore = New-Object Microsoft.SqlServer.Management.Smo.Restore
        $dbrestore.NoRecovery = $false;
        $dbrestore.ReplaceDatabase = $true;
        $dbrestore.Database = $dbname 
        $dbrestore.PercentCompleteNotification = 10;
        $dbrestore.Devices.Add($backupDevice)
        $dbRestoreDetails = $dbrestore.ReadBackupHeader($destObj)
        $logicalFileNameList = $dbrestore.ReadFileList($destObj)         
       
        
        foreach($row in $logicalFileNameList)
        { 
                  
            if ($row.fileId -eq 1) 
            {
            
            $dbRestoreFile = New-Object("Microsoft.SqlServer.Management.Smo.RelocateFile") 
            $dbRestoreFile.LogicalFileName = $row.LogicalName
            $dbRestoreFile.PhysicalFileName = $DestiDataPath + $dbname + '.mdf'       
            $dbrestore.RelocateFiles.Add($dbRestoreFile) |Out-Null
       
            }
            elseif ($row.fileId -eq 2) 
            {
       
            $dbRestoreLog = New-Object("Microsoft.SqlServer.Management.Smo.RelocateFile")
            $dbRestoreLog.LogicalFileName = $row.LogicalName
            $dbRestoreLog.PhysicalFileName = $DestiLogPath + $dbname + '_log.ldf'            
            $dbrestore.RelocateFiles.Add($dbRestoreLog) |out-null
         
            }  
                      
            elseif ($row.fileid -eq 3) 
            {
             
            $dbRestoreFile2 = New-Object("Microsoft.SqlServer.Management.Smo.RelocateFile") 
            $dbRestoreFile2.LogicalFileName = $row.LogicalName
            $dbRestoreFile2.PhysicalFileName = $DestiDataPath2 + $dbname + "_ndf" + 1 + '.ndf'       
            $dbrestore.RelocateFiles.Add($dbRestoreFile2)|Out-Null
      
            }    
              elseif ($row.fileid -eq 4) 
            {
             
            $dbRestoreFile2 = New-Object("Microsoft.SqlServer.Management.Smo.RelocateFile") 
            $dbRestoreFile2.LogicalFileName = $row.LogicalName
            $dbRestoreFile2.PhysicalFileName = $DestiDataPath2 + $dbname + "_ndf" + 2 + '.ndf'       
            $dbrestore.RelocateFiles.Add($dbRestoreFile2)|Out-Null
           
            } 
              elseif ($row.fileid -eq 5) 
            {
             
            $dbRestoreFile2 = New-Object("Microsoft.SqlServer.Management.Smo.RelocateFile") 
            $dbRestoreFile2.LogicalFileName = $row.LogicalName
            $dbRestoreFile2.PhysicalFileName = $DestiDataPath2 + $dbname + "_ndf" + 3 + '.ndf'       
            $dbrestore.RelocateFiles.Add($dbRestoreFile2)|Out-Null
          
            } 
              elseif ($row.fileid -eq 6) 
            {
             
            $dbRestoreFile2 = New-Object("Microsoft.SqlServer.Management.Smo.RelocateFile") 
            $dbRestoreFile2.LogicalFileName = $row.LogicalName
            $dbRestoreFile2.PhysicalFileName = $DestiDataPath2 + $dbname + "_ndf" + 4 + '.ndf'       
            $dbrestore.RelocateFiles.Add($dbRestoreFile2)|Out-Null
            } 
              elseif ($row.fileid -eq 7) 
            {
             
            $dbRestoreFile2 = New-Object("Microsoft.SqlServer.Management.Smo.RelocateFile") 
            $dbRestoreFile2.LogicalFileName = $row.LogicalName
            $dbRestoreFile2.PhysicalFileName = $DestiDataPath2 + $dbname + "_ndf" + 5 + '.ndf'       
            $dbrestore.RelocateFiles.Add($dbRestoreFile2)|Out-Null
          
            }       
                               
         } 
            $dbrestore.SqlRestore($destObj)
            write-host "RESTORE JOB >> " $dbname -ForegroundColor green        
         
     } 
            
     }   
     catch 
     { 
        $err = $_.Exception
        write-host $err.Message -ForegroundColor Magenta
         
        while( $err.InnerException ) 
        {
            $err = $err.InnerException
            write-host $err.Message -ForegroundColor yellow
        }
        
     }
} # outer for
write-host "##############################"
asnp SqlServer* -ea 0 ## Snapin SQL
write-host  "DBS Check after migration " -ForegroundColor Yellow
#$destObj.Databases| where {$_.IsSystemObject -eq $false } | select Name,status,Size,PhysicalFileName |ft -AutoSize
Invoke-Sqlcmd -ServerInstance $destiServer -Query "select name,file_id,type_desc,physical_name from sys.master_files where database_id > 5" |ft -AutoSize


remove-variable destiServer
remove-variable i
remove-variable j
remove-variable dbname
remove-variable sourceServer




