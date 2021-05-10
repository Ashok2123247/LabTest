### Health Check Report
### version 1.1
### Modified date 16/05/2019
##################################################################

## Variable declaration
clear-host
$ErrorActionPreference = "Stop"
asnp SqlServer* -ea 0
$line = "-" * 70
$InstanceNames = Read-Host "Enter Servername >>"

#$servernames= "ASHOK\Primarysrv"
#$servernames=Read-Host "Please enter a SQL Server Name"
#$servernames = get-content C:\HC\Srv.txt

$Date = Get-Date -Format yyyyMMdd_HHmmss
$pathDir = "C:\temp\"
$dt = get-date -format yyyyMMdd_HHmmss
$filedate = (Get-Date).tostring(“dd-MM-yyyy-Hmm”)
$filename = $pathDir + 'HealthCheckReport_' + $filedate + '.html'

##For HTML Display

$a = "<style>"
$a = $a + "BODY{background-color:white;}"
$a = $a + "TABLE{border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;font:0.7em/145% Segoe UI,helvetica,Segoe UI,Segoe UI;}"
$a = $a + "TH{border-width: 1px;padding: 3px;border-style: solid;border-color: black;background-color:#778899}"
$a = $a + "TD{border-width: 1px;padding: 3px;border-style: solid;border-color: black;}"
$a = $a + "tr:nth-child(odd) { background-color:#d3d3d3;}"
$a = $a + "tr:nth-child(even) { background-color:white;}"
$a = $a + "</style>"

##SQL Starttime details
##======================================================================================
$SQLStartTime = "DECLARE @server_start_time DATETIME,@seconds_diff INT,@days_online INT,
@hours_online INT,@minutes_online INT,@seconds_online INT ;
SELECT @server_start_time=crdate FROM sysdatabases WHERE NAME='tempdb'
SELECT @seconds_diff = DATEDIFF(SECOND, @server_start_time, GETDATE()),
@days_online = @seconds_diff / 86400, @seconds_diff = @seconds_diff % 86400,
@hours_online = @seconds_diff / 3600, @seconds_diff = @seconds_diff % 3600,
@minutes_online = @seconds_diff / 60, @seconds_online = @seconds_diff % 60 ;
SELECT @server_start_time AS server_start_time,@days_online AS days_online,
@hours_online AS hours_online,@minutes_online AS minutes_online,@seconds_online AS seconds_online;"

##SQL Version Details
##======================================================================================
$DBVersion = "select CAST( SERVERPROPERTY('MachineName') AS NVARCHAR(128)) AS [MachineName],
CAST( SERVERPROPERTY('ServerName')AS NVARCHAR(128)) AS [SQLServerName],
CAST( SERVERPROPERTY('IsClustered') AS NVARCHAR(128)) AS [IsClustered],
CAST( SERVERPROPERTY('ComputerNamePhysicalNetBIOS')AS NVARCHAR(128)) AS [SQLService_Current_Node],
serverproperty('edition') as [Edition],serverproperty('productlevel') as [Servicepack],
CAST( SERVERPROPERTY('InstanceName') AS NVARCHAR(128)) AS [InstanceName], substring(@@version,1,50) as [Serverversion];"

##SQL Database Status Info
##======================================================================================
$DBStatus = "select @@servername as ServerName,name as DBName,compatibility_level as CMPLevel,state_desc as DBStatus,
 recovery_model_desc as RecoveryModel from sys.databases where name not in ('master','tempdb', 'msdb','model');"
 
##SQL Current Active Sessions
##======================================================================================
$CurrentSessions = "SELECT status,command,percent_complete as percentage,session_id,DB_NAME(Database_id) DBName,
(estimated_completion_time/1000)/60 Est_Min,cpu_time,row_count,reads,writes,request_id,start_time FROM sys.dm_exec_requests 
WHERE status not in ('sleeping','background') or command in ('backup database','backup log','update','insert');"

##SQL Backup Info since last 3 days
##======================================================================================
$BackupInfo = "select bs.Database_name, cast(bs.backup_size/1024/1024 as decimal(10,2)) as Backupsize_MB,
CAST(bs.compressed_backup_size/1024/1024 as decimal(10,2)) as Compressedsize_MB, 
bs.Backup_start_date, bs.Backup_finish_date,
--CAST(DATEADD(MINUTE,DATEDIFF(s,bs.backup_start_date,bs.backup_finish_date),'2011-01-01 00:00:00') as Time)as Duration,
CONVERT(VARCHAR(10),DATEADD(MINUTE,DATEDIFF(s,bs.backup_start_date,bs.backup_finish_date),'2011-01-01 00:00:00'),108)as Duration,
bf.Physical_device_name
from msdb.dbo.backupset bs join msdb.dbo.backupmediafamily bf 
on bs.media_set_id = bf.media_set_id 
where type='D' and bs.backup_start_date BETWEEN DATEADD(hh, -48, GETDATE()) and getdate()
and bs.database_name not in ('master', 'msdb', 'model', 'sqladmin')
order by bs.database_name;"

##SQL Logfile Info
##======================================================================================
$LogfileStatus = "if exists (select * from tempdb.sys.all_objects where name like '##tbl_dbinfo')
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

select * from ##tbl_dbinfo
where (Filepath like '%SL0%.ldf'or Filepath like '%SL1%.ldf' or Filepath like '%SL2%' or Filepath like '%.ldf') 

drop table ##tbl_dbinfo"

##SQL Blockages Info
##======================================================================================
$Blockages = "select	@@servername as ServerName,rtrim((case when t1.dbid = 0 then null when t1.dbid <>0 then db_name(t1.dbid) end)) as DBName,
		t1.spid, t1.status, t1.loginame, t1.program_name,t1.blocked,t1.cmd,		 
		datediff(minute,t1.last_batch, getdate()) as waittime_db,t1.cpu, t1.last_batch,
		substring(sql.text,0,120) as sqlquery
from master.dbo.sysprocesses t1
cross apply sys.dm_exec_sql_text(t1.sql_handle) as sql
where t1.blocked <> 0 
order by t1.dbid desc, t1.spid;"


##For Disply
##======================================================================================
foreach ($Instance in $InstanceNames)
{	try
    {
	    clear-host
        Write-Host –NoNewLine "Please wait while running script....."   
	          
        $Server = $Instance.Split("\")
	    $ServerName = $Server[0]  
          
	
    clear-host
	write-host $line 
   	write-host "1 : Version and edition details" 
	write-host "2 : SQL Services status" 
	write-host "3 : Database Status" 
	write-host "4 : SQL Start time" 
	write-host "5 : Server Reboot Time" 
	write-host "6 : Disk Information" 
	write-host "7 : Blocking process" 
	write-host "8 : Current active transactions" 
	write-host "9 : Last 2 days backup information"	
	write-host "10: LogSize Inforation"
    write-host "11: Last 48 hours errors"

    write-host "12: All Options with HTML Report"  
	write-host $line

 	##Choosing options 
	$option = Read-Host "Choose the options "	
	$option=$option.Split(',')
	
	if($option -ne 0 -and $option -ne $null)
	{	clear-host
	
		##If multiple options
		foreach($Opt in $option)
		{	

##Switch Starts
##======================================================================================		
			switch ($Opt)
			{
	1
	{	write-host " "
        write-host "SQL Server VERSION Details " -foregroundcolor green 
		write-host $line
		Invoke-Sqlcmd -ServerInstance $Instance -Query $DBVersion |Format-Table -AutoSize		 
	}	
	2
	{	write-host " "
        write-host "SQL Services status"-foregroundcolor green $ServerName
		write-host $line
		get-service -computerName $ServerName |where-object {$_.Name -like '*MSSQL$*'-OR $_.Name -like '*SQLAgent$*'} |Format-Table DisplayName,Name,Status -autosize
	}		
	3
	{	write-host " "
        write-host "Database Status"-foregroundcolor green  
		write-host $line
		Invoke-Sqlcmd -ServerInstance $Instance -Query $DBStatus |Format-Table ServerName,DBName,CMPLevel,RecoveryModel,DBStatus -AutoSize 
	}	
	4
	{	write-host " "
        write-host "SQL Server start time "-foregroundcolor green $Instance
		write-host $line
		Invoke-Sqlcmd -ServerInstance $Instance -Query $SQLStartTime|Format-Table -autosize	
	}	
	5
	{	write-host " "
        write-host "SQL Server Last Reboot Time "-foregroundcolor green $ServerName
		write-host $line
		write-host 
		$os = Get-WmiObject win32_operatingsystem -ComputerName $ServerName |select @{LABEL=’LastBootUpTime’;EXPRESSION={$_.ConverttoDateTime($_.lastbootuptime)}}
		$uptime = (Get-Date) - $os.LastBootUpTime
		Write-host "LatBootTime : " $os.LastBootUpTime (" [ Uptime: " + $uptime.Days + " Days " + $uptime.Hours + " Hours " + $uptime.Minutes + " Minutes ]")
		write-host " " 
	}
	6
	{	write-host "Disk Management"-foregroundcolor green 
		write-host $line
		Get-WmiObject -computername $ServerName -query "select SystemName, DriveType, FileSystem, FreeSpace, Capacity, Label,Caption
		from Win32_Volume where DriveType = 2 or DriveType = 3" | ForEach { New-Object PSObject -Property @{
        SystemName = $_.systemName
        LABEL = $_.Label
        TargetName = $_.Caption
        SIZEInGB = ([Math]::Round($_.Capacity/1GB,2))
        UsedSizeInGB = ([Math]::Round($_.Capacity/1GB - $_.FreeSpace/1GB,2))
        FREESizeInGB = ([Math]::Round($_.FreeSpace/1GB,2))
        UsedPercentage =  ([Math]::Round(($_.Capacity/1GB - $_.FreeSpace/1GB)/($_.Capacity/1GB) * 100,2))
        FreePercentage = ([Math]::Round(($_.freespace/1GB)/ ($_.Capacity/1GB) * 100,2))
        DiskStatus = if(([Math]::Round(($_.freespace/1GB)/ ($_.Capacity/1GB) * 100)) -lt 10){'NOT HEALTHY' }else {'HEALTHY'}
    }}|Format-Table SystemName,LABEL,SIZEInGB,UsedSizeInGB,FREESizeInGB,UsedPercentage,FreePercentage,DiskStatus -autosize	}	
	7
	{	write-host " "
        write-host "Current blockages" -foregroundcolor green 
		write-host $line
		$Opt8 = Invoke-Sqlcmd -ServerInstance $Instance -Query $Blockages
        
		If($Opt8 -eq 0 -or $Opt8 -eq $null){write-host "No Blockages found" -foregroundcolor yellow }
		else {$Opt8 |Format-Table -AutoSize}
	}
	8
	{	write-host " "
        write-host "Current Active Transactions" -foregroundcolor green $Instance
		write-host $line
		$Opt2 = Invoke-Sqlcmd -ServerInstance $Instance -Query $CurrentSessions 
		If($Opt2 -eq 0 -or $Opt2 -eq $null){write-host -foregroundcolor yellow "Zero Active Transactions found"}
		else {$Opt2 |Format-Table -autosize }
	}		
	9
	{	write-host " "
        write-host "Last 2 days backup information" -foregroundcolor green $Instance
		write-host $line
		$backup = Invoke-Sqlcmd -ServerInstance $Instance -Query $BackupInfo  
		If($backup -eq 0 -or $backup -eq $null){write-host -foregroundcolor Magenta "There is no backup since last 48 hours "} else {$backup |Format-Table -AutoSize }	
	}
	10
	{	write-host " "
        write-host "DBLogFile Status"-foregroundcolor green 
		write-host $line
		Invoke-Sqlcmd -ServerInstance $Instance -Query $LogfileStatus | Format-Table -AutoSize 
	}
    11
    {
        write-host " "
        write-host "Error Log Information since last 24 hours"-foregroundcolor green 
		write-host $line
        Get-EventLog -computername $ServerName -After (Get-Date).AddHours(-24) -LogName "Application" -entrytype "error"|`
        Where-Object {$_.Source -like 'MSSQL$*' -or $_.Source -like 'MSSQLSEVER'} | ft -AutoSize
    }
    
	12
	{	write-host " "
        Write-host "Please wait while running script " 
        for ($I = 1; $I -le $Instance.Length; $I++ )
        {Write-Progress -Activity "Report in Progress" -Status "$I% Complete:" -PercentComplete $I;}	
         
		Invoke-Sqlcmd -ServerInstance $Instance -Query $DBVersion|Select-Object MachineName,SQLServerName,IsClustered,Edition,InstanceName,Serverversion|ConvertTo-HTML -head $a -body "<h3><center><u>SQLServer HealthCheck Report</u></center></h3><H4><u>SQL Version Details</u></H4>"| Out-File  $filename
		get-service -computerName $ServerName |where-object {$_.Name -like 'MSSQL$*'-OR $_.Name -like 'SQLAgent$*'}|select-Object name,DisplayName,status |ConvertTo-HTML -head $a -body "<H4><u>SQL Services status</u></H4>"| Out-File -append $filename
		Invoke-Sqlcmd -ServerInstance $Instance -Query $SQLStartTime |Select-Object server_start_time,days_online,hours_online,minutes_online,seconds_online|ConvertTo-HTML -head $a -body "<H4><u>SQL StartTime</u></H4>"| Out-File -append $filename
		Invoke-Sqlcmd -ServerInstance $Instance -Query $DBStatus |Select-Object ServerName,DBName,CMPLevel,RecoveryModel,DBStatus|ConvertTo-HTML -head $a -body "<H4><u>Database Status</u></H4>"| Out-File -append $filename
		
		Get-WmiObject -computername $ServerName -query "select SystemName, DriveType, FileSystem, FreeSpace, Capacity, Label
		from Win32_Volume where DriveType = 2 or DriveType = 3" | ForEach { New-Object PSObject -Property @{
        SystemName = $_.systemName
        LABEL = $_.Label
        SIZEInGB = ([Math]::Round($_.Capacity/1GB,2))
        UsedSizeInGB = ([Math]::Round($_.Capacity/1GB - $_.FreeSpace/1GB,2))
        FREESizeInGB = ([Math]::Round($_.FreeSpace/1GB,2))
        UsedPercentage =  ([Math]::Round(($_.Capacity/1GB - $_.FreeSpace/1GB)/($_.Capacity/1GB) * 100,2))
        FreePercentage = ([Math]::Round(($_.freespace/1GB)/ ($_.Capacity/1GB) * 100,2))
        DiskStatus = if(([Math]::Round(($_.freespace/1GB)/ ($_.Capacity/1GB) * 100)) -lt 10){'NOT HEALTHY' }else {'HEALTHY'}
		}}|Select-Object SystemName,LABEL,SIZEInGB,UsedSizeInGB,FREESizeInGB,UsedPercentage,FreePercentage,DiskStatus |ConvertTo-HTML -head $a -body "<H4><u>Disk Management</u></H4>"| Out-File -append $filename		
		
		Invoke-Sqlcmd -ServerInstance $Instance -Query $LogfileStatus|Select-Object Name,sizeMB,AvailableMB,AvailablePCT,FilePath  |ConvertTo-HTML -head $a -body "<H4><u>Log File Information</u></H4>"| Out-File -append $filename
		Invoke-Sqlcmd -ServerInstance $Instance -Query $BackupInfo|Select-Object Database_name,Backupsize_MB,Compressedsize_MB,Backup_start_date,Backup_finish_date,Duration,Physical_device_name|ConvertTo-HTML -head $a -body "<H4><u>Last 2 days backup info </u></H4>"| Out-File -append $filename
		Invoke-Sqlcmd -ServerInstance $Instance -Query $Blockages |`
        Select-Object ServerName,DBName,spid,status,loginame,program_name,blocked,cmd,waittime_db,cpu,last_batch,sqlquery |ConvertTo-HTML -head $a -body "<H4><u>Current Blockings info  </u></H4>"| Out-File -append $filename

        Invoke-Sqlcmd -ServerInstance $Instance -Query $CurrentSessions|Select-Object status,command,percentage,session_id,DBName,est_min,cpu_time,row_count,reads,writes,request_id,start_time |ConvertTo-HTML -head $a -body "<H4><u>Current Active Sessions </u></H4>"| Out-File -append $filename
		
        write-host "`nHealthCheck Report has been generated successfully" -ForegroundColor green 
        write-host "`nHC Report file under this path >>>" $filename -ForegroundColor green 
	}
	
	
	
	}##Switch Ends
	##======================================================================================

	}#Foreach
	}#If
	else {Write-host "you haven't chosen options.... Please try again " -foregroundcolor yellow}
	
}#try
	catch{ write-host "InstanceName :" $Instance `n"SQL Service is not in available either may be OFFLINE or not in ACTIVE" -ForegroundColor Magenta }
}#main foreach

