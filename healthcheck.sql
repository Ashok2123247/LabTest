##======================================================================================
#HealthCheck Report by using Powershell
#Author : Ashok Sagar
##======================================================================================
$ErrorActionPreference = "Stop"
$InstanceNames = Read-Host "Please enter the[ServerName\InstanceName]"
#$servernames= "ASHOK\Primarysrv"
#$servernames=Read-Host "Please enter a SQL Server Name"
#$servernames = get-content C:\DBA\HCReports\Servers.txt

$Date = Get-Date -Format yyyyMMdd_HHmmss

$pathDir = "C:\DBA\HCReports\"
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

$line = "-" * 118


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
$BackupInfo = "select bs.database_name as DBName, cast(bs.backup_size/1024/1024 as decimal(10,2)) as BAKSizeMB,
CAST(bs.compressed_backup_size/1024/1024 as decimal(10,2)) as CMPSizeMB, bs.backup_start_date as BAKStartDate, 
bs.backup_finish_date as BAKFinishDate,DATEDIFF(MINUTE,bs.backup_start_date,bs.backup_finish_date)as BAK_DurationMIN 
from msdb.dbo.backupset bs join msdb.dbo.backupmediafamily bf on bs.media_set_id = bf.media_set_id 
where type='D' and bs.backup_start_date BETWEEN DATEADD(hh, -72, GETDATE()) and getdate()
and bs.database_name not in ('master', 'msdb', 'model', 'sqladmin')
order by bs.database_name;"

##SQL Logfile Info
##======================================================================================
$LogfileStatus = "SELECT name,db.recovery_model_desc as RecoveryModel
, db.log_reuse_wait_desc
, ((ls.cntr_value)/128.0)  AS size_MB
, ((lu.cntr_value)/128.0) AS used_MB
, CAST(((lu.cntr_value)/128.0) AS FLOAT) / CAST(((ls.cntr_value)/128.0) AS FLOAT) 
  AS used_percent
, CASE WHEN CAST(((lu.cntr_value)/128.0) AS FLOAT) / CAST(((ls.cntr_value)/128.0) AS FLOAT) > .5 THEN
   CASE
    /* tempdb special monitoring */
    WHEN db.name = 'tempdb' 
     AND log_reuse_wait_desc NOT IN ('CHECKPOINT', 'NOTHING') THEN 'WARNING' 
    /* all other databases, monitor foor the 50% fill case */
    WHEN db.name <> 'tempdb' THEN 'WARNING'
    ELSE 'OK'
    END
  ELSE 'OK' END
  AS log_status
FROM sys.databases db
JOIN sys.dm_os_performance_counters lu
 ON db.name = lu.instance_name
JOIN sys.dm_os_performance_counters ls
 ON db.name = ls.instance_name
WHERE lu.counter_name LIKE  'Log File(s) Used Size (KB)%'
AND ls.counter_name LIKE 'Log File(s) Size (KB)%'
AND ls.cntr_value > 0 OPTION (RECOMPILE);"


##For Disply
##======================================================================================
foreach ($Instance in $InstanceNames)
{	try
    {
	    clear-host
        Write-Host –NoNewLine "Please wait while running script "
      
	$Server = $Instance.Split("\")
	$ServerName = $Server[0]
	asnp SqlServer* -ea 0
	clear-host
	write-host $line -foregroundcolor darkgray
	write-host "1 : Version and edition details" -foregroundcolor gray
	write-host "2 : SQL Services status" -foregroundcolor gray
	write-host "3 : Database Status" -foregroundcolor gray
	write-host "4 : SQL Start time" -foregroundcolor gray
	write-host "5 : Server Reboot Time" -foregroundcolor gray
	write-host "6 : Disk Information" -foregroundcolor gray
	write-host "7 : Blocking process" -foregroundcolor gray
	write-host "8 : Current active transactions" -foregroundcolor gray
	write-host "9 : Last 3 days backup information"	-foregroundcolor gray
	write-host "10: LogSize Inforation" -foregroundcolor gray	
	write-host "11: All Options with HTML Report" -foregroundcolor gray	
	write-host $line -foregroundcolor darkgray 
	
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
	{	write-host "SQL Server VERSION Details " -foregroundcolor green 
		write-host $line
		Invoke-Sqlcmd -ServerInstance $Instance -Query $DBVersion |Format-Table -AutoSize		 
	}	
	2
	{	write-host "SQL Services status"-foregroundcolor green $ServerName
		write-host $line
		get-service -computerName $ServerName |where-object {$_.Name -like 'MSSQL$*'-OR $_.Name -like 'SQLAgent$*'} |Format-Table DisplayName,Name,Status -autosize
	}		
	3
	{	write-host "Database Status"-foregroundcolor green  
		write-host $line
		Invoke-Sqlcmd -ServerInstance $Instance -Query $DBStatus |Format-Table ServerName,DBName,CMPLevel,RecoveryModel,DBStatus -AutoSize 
	}	
	4
	{	write-host "SQL Server start time "-foregroundcolor green $Instance
		write-host $line
		Invoke-Sqlcmd -ServerInstance $Instance -Query $SQLStartTime|Format-Table -autosize	
	}	
	5
	{	write-host "SQL Server Last Reboot Time "-foregroundcolor green $ServerName
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
    }}|Format-Table SystemName,LABEL,SIZEInGB,UsedSizeInGB,FREESizeInGB,UsedPercentage,FreePercentage,DiskStatus -autosize	}	
	7
	{	write-host "Current blockages" -foregroundcolor green 
		write-host $line
		$Opt1 = Invoke-Sqlcmd -ServerInstance $Instance -Query "select * from sys.sysprocesses where blocked >0"
		If($Opt1 -eq 0 -or $Opt1 -eq $null){write-host -foregroundcolor yellow "Zero Blockages found"}
		else {$Opt1 |Format-Table -autosize}
	}
	8
	{	write-host "Current Active Transactions" -foregroundcolor green $Instance
		write-host $line
		$Opt2 = Invoke-Sqlcmd -ServerInstance $Instance -Query $CurrentSessions 
		If($Opt2 -eq 0 -or $Opt2 -eq $null){write-host -foregroundcolor yellow "Zero Active Transactions found"}
		else {$Opt2 |Format-Table -autosize }
	}		
	9
	{	write-host "Last 3 days backup information" -foregroundcolor green $Instance
		write-host $line
		$backup = Invoke-Sqlcmd -ServerInstance $Instance -Query $BackupInfo  
		If($backup -eq 0 -or $backup -eq $null){write-host -foregroundcolor Magenta "There is no backup since last 72 hours "} else {$backup |Format-Table -AutoSize }	
	}
	10
	{	write-host "DBLogFile Status"-foregroundcolor green 
		write-host $line
		Invoke-Sqlcmd -ServerInstance $Instance -Query $LogfileStatus |Format-Table -AutoSize 
	}
	11
	{	Write-Host –NoNewLine "Please wait while running script "
        foreach($element in 1..9)
            { Write-Host –NoNewLine  " " -BackgroundColor "Green"
                    Start-Sleep –Seconds 1
                    
                    }		 
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
        DiskStatus = if(([Math]::Round(($_.freespace/1GB)/ ($_.Capacity/1GB) * 100)) -lt 10){'NOTHEALTHY' }else {'HEALTHY'}
		}}|Select-Object SystemName,LABEL,SIZEInGB,UsedSizeInGB,FREESizeInGB,UsedPercentage,FreePercentage,DiskStatus |ConvertTo-HTML -head $a -body "<H4><u>Disk Management</u></H4>"| Out-File -append $filename		
		
		Invoke-Sqlcmd -ServerInstance $Instance -Query $LogfileStatus|Select-Object name,RecoveryModel,log_reuse_wait_desc,size_MB, used_MB ,used_percent, log_status  |ConvertTo-HTML -head $a -body "<H4><u>Log File Information</u></H4>"| Out-File -append $filename
		Invoke-Sqlcmd -ServerInstance $Instance -Query $BackupInfo|Select-Object DBName,BAKSizeMB,CMPSizeMB,BAKStartDate,BAKFinishDate,BAK_DurationMIN |ConvertTo-HTML -head $a -body "<H4><u>Last 3 days backup info </u></H4>"| Out-File -append $filename
		Invoke-Sqlcmd -ServerInstance $Instance -Query $CurrentSessions|Select-Object status,command,percentage,session_id,DBName,est_min,cpu_time,row_count,reads,writes,request_id,start_time |ConvertTo-HTML -head $a -body "<H4><u>Current Active Sessions </u></H4>"| Out-File -append $filename
		"`nHealthCheck Report has been generated successfully (file path : C:\DBA\HCReports)";
	}
	
	
	
	}##Switch Ends
	##======================================================================================

	}#Foreach
	}#If
	else {Write-host "you haven't chosen options.... Please try again " -foregroundcolor yellow}
	
}#try
	catch{ write-host -foregroundcolor magenta "****WARNING***** `n`nInstanceName :" $Instance `n"SQL Services are not in online status or May be Network Error or Instancename is not valid"}
}#main foreach

### Removing variables
remove-variable InstanceNames
remove-variable Date
remove-variable pathDir
remove-variable dt
remove-variable filedate
remove-variable filename
remove-variable a
remove-variable line
remove-variable SQLStartTime
remove-variable DBVersion
remove-variable DBStatus
remove-variable CurrentSessions
remove-variable BackupInfo
remove-variable LogfileStatus
remove-variable Instance
remove-variable Server
remove-variable ServerName
remove-variable option

