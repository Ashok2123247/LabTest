## Script to Shrink Log file 
## Version 3
## Author Ashok Sagar
## This script will not work if there are any active connections on DB
## ####################################################################
Clear-Host
asnp SqlServer* -ea 0

## Variable declaration 
#$InstanceName = "EAPMSSQLK24Q"
$InstanceName = Read-Host "Enter ServerName >>>"

## SQL Script for current transactions
$Currentstatus = "SELECT status,command,percent_complete as percentage,session_id,DB_NAME(b.Database_id) DBName,
isnull(suser_sname(owner_sid),'~~UNKNOWN~~')as DBUser,
(estimated_completion_time/1000)/60 Est_Min,cpu_time,start_time FROM sys.dm_exec_requests a 
join sys.databases b ON a.database_id = b.database_id
WHERE status not in ('sleeping','background') and
command in ('backup database','backup log');"

## SQL Query 
$DiskInfo = "SELECT distinct vs.volume_mount_point AS DriveName,
vs.total_bytes/1073741824 as TotalSize_GB, 
vs.available_bytes/1073741824 AS FreeSpace_GB, 
(vs.total_bytes/1073741824) - 
(vs.available_bytes/1073741824) AS SpaceUsed_GB, 
CAST(CAST(vs.available_bytes AS FLOAT)/ CAST(vs.total_bytes AS FLOAT) AS DECIMAL(18,3)) * 100 AS [FreeSpacePCT],
SERVERPROPERTY('MachineName') AS [ServerName]
FROM sys.master_files AS mf 
CROSS APPLY sys.dm_os_volume_stats(mf.database_id, mf.file_id) AS vs
where vs.volume_mount_point like '%SL0%' or vs.volume_mount_point like '%SL1%'
ORDER BY vs.volume_mount_point"


$DiskInfoOld = Invoke-Sqlcmd -ServerInstance $InstanceName -query $DiskInfo

## LogFile Information
write-host "Log file size over 1 GB " -ForegroundColor Green

$DBScritp = "if exists (select * from tempdb.sys.all_objects where name like '##tbl_dbinfo')
drop table ##tbl_dbinfo

-- Temp table creation
create table ##tbl_dbinfo
    (name     varchar(300),
     sizeMB decimal(20,2),
     AvailableMB decimal (20,2),
     AvailablePCT decimal(20,3),
     Filepath varchar(1000))
INSERT INTO ##tbl_dbinfo (name,sizeMB,AvailableMB,AvailablePCT,Filepath)
EXEC sp_MSforeachdb
'
use [?]
SELECT ''?'' as DBName,((size)/128.0) as sizeMB ,
((size)/128.0) - CAST(FILEPROPERTY(name, ''SpaceUsed'') AS decimal)/128.0 AS AvailableSpaceMB,
((((size)/128.0) - CAST(FILEPROPERTY(name, ''SpaceUsed'') AS decimal)/128.0) / ((size)/128.0)) * 100  as AvailablePCT
,filename FROM sysfiles ';

select @@SERVERNAME as ServerName,* from ##tbl_dbinfo 
where Filepath like '%SL0%.ldf' and sizeMB > 1024

drop table ##tbl_dbinfo"

$NoFiles = Invoke-Sqlcmd -ServerInstance $InstanceName -query $DBScritp

    if($NoFiles -ne 0 -and $NoFiles -ne $null)
    { $NoFiles | Select-Object ServerName, Name,SizeMB,AvailableMB,AvailablePCT,Filepath | ft -AutoSize }
    else 
    {   write-host "No files found above 1 GB " -ForegroundColor Magenta 
        Exit 
    }

Write-host "Current Backup Status" -ForegroundColor Green
Write-Warning "Shrink command will not work on current running backup database" 
$JobStatus1 = Invoke-Sqlcmd -ServerInstance $InstanceName -query $Currentstatus
$JobStatus1 | Select-Object status,command,percentage,session_id,DBName,DBUser,est_Min,start_time| ft -AutoSize
    
$DatabaseName = Read-Host "Enter Database name >>>"

## LogBackup Job execution

write-host "Existing Log Backup job info" -ForegroundColor Green

## Existing log backup job script
$DBScritp2 = "select name,enabled,date_created,date_modified from msdb.dbo.sysjobs where name like '%"+$DatabaseName+"%' and name like '%Log Backup%'"


$JobStatus = Invoke-Sqlcmd -ServerInstance $InstanceName -query $DBScritp2 

    if ($JobStatus -ne 0 -and $JobStatus -ne $null)
    { $JobStatus | Select-Object name,enabled,date_created,date_modified| ft -AutoSize }
    else 
    { Write-Warning "There is no log backup job, Please create and try" -ForegroundColor magenta
    Write-host "To continue, choose the option 2 " -ForegroundColor magenta}



$DBScritp1 = "USE [msdb]
GO
declare @dbname varchar(100)
select @dbname = name from dbo.sysjobs where name like '%"+$DatabaseName+"%' and name like '%Log Backup%'
EXEC msdb.dbo.sp_start_job  @job_name = @dbname"

write-host " "
write-host "To run Log backup Job [YES] = 1 [NO] = 2 " -ForegroundColor green

$option = Read-Host "Enter your option"
	
	if($option -ne 0 -and $option -ne $null)
	{
        
        switch ($option)
        {
          1
            {
                $a = Invoke-Sqlcmd -ServerInstance $InstanceName -query $DBScritp1 -Database $DatabaseName
                
                    if($a -ne 0 -and $a -ne $null)
                    {write-host "Job failed " -ForegroundColor red}
                    else 
                    {
<#                        Write-host "Current Backup Status" -ForegroundColor Green
                        #$JobStatus1 = Invoke-Sqlcmd -ServerInstance $InstanceName -query $Currentstatus

                            if ($JobStatus1 -ne 0 -and $JobStatus1 -ne $null)
                            {Start-Sleep -s 5  
                            $JobStatus1 | Select-Object status,command,percentage,session_id,DBName,DBUser,est_Min,start_time| ft -AutoSize }
                            else 
                            { write-host "No active backup jobs" -ForegroundColor magenta }
                             
 #>                 Start-Sleep -s 10 
                    write-host "Job executed successfully" -ForegroundColor green
                    }
            }
          2
            {
            write-host "User has skip to run the JOB" -ForegroundColor green
            }
        }
    }


## Shrink File 

$ScriptFile3 = "declare @logicalFile_log varchar(50)
select @logicalFile_log = name from sys.master_files where physical_name like '%"+$DatabaseName+"%.ldf'
DBCC SHRINKFILE (@logicalFile_log, 0, TRUNCATEONLY)"

write-host " "
write-host "To Shrink Log file [YES] = 1 [NO] = 2 " -ForegroundColor green
$option1 = Read-Host "Enter your option"
	
	if($option1 -ne 0 -and $option1 -ne $null)
	{
        
        switch ($option1)
        {
          1
            {
                try {
                Invoke-Sqlcmd -ServerInstance $InstanceName -query $ScriptFile3 -Database $DatabaseName|`
                Select-Object dbId, FileId,CurrentSize,MinimumSize,UsedPages,EstimatedPages |ft -AutoSize
                }
                catch {Write-host "Active connections existed on this datbase" -ForegroundColor Magenta}
                
            }
          2
            {
            write-host "User has canceled the operation" -ForegroundColor green
            }

        }
    }

Write-host "LogFile status after shrink" -ForegroundColor Green
Invoke-Sqlcmd -ServerInstance $InstanceName -query $DBScritp -Database $DatabaseName |`
Select-Object ServerName, Name,SizeMB,AvailableMB,AvailablePCT,Filepath | ft -AutoSize

write-host "Disk Info before shrink " -ForegroundColor Green
$DiskInfoOld |Select-Object DriveName,TotalSize_GB,FreeSpace_GB,SpaceUsed_GB,FreeSpacePCT,ServerName| ft -AutoSize

write-host "Disk Info after shrink " -ForegroundColor Green
$DiskInfoNew = "SELECT distinct vs.volume_mount_point AS DriveName,
vs.total_bytes/1073741824 as TotalSize_GB, 
vs.available_bytes/1073741824 AS FreeSpace_GB, 
(vs.total_bytes/1073741824) - 
(vs.available_bytes/1073741824) AS SpaceUsed_GB, 
CAST(CAST(vs.available_bytes AS FLOAT)/ CAST(vs.total_bytes AS FLOAT) AS DECIMAL(18,3)) * 100 AS [FreeSpacePCT],
SERVERPROPERTY('MachineName') AS [ServerName]
FROM sys.master_files AS mf 
CROSS APPLY sys.dm_os_volume_stats(mf.database_id, mf.file_id) AS vs
where vs.volume_mount_point like '%SL%'
ORDER BY vs.volume_mount_point"
Invoke-Sqlcmd -ServerInstance $InstanceName -query $DiskInfoNew |`
Select-Object DriveName,TotalSize_GB,FreeSpace_GB,SpaceUsed_GB,FreeSpacePCT,ServerName| ft -AutoSize

