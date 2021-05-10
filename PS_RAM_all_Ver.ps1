### Health Check Report For RAM and DBs Status
### Ashok Sagar 
### Varsion : 2
### Create Date : 16/11/2018
###################################################
<## ServerName with InstanceName
    Current Allocation RAM
    Total RAM
    SUM of DBS Size
    Number Of DBS Count
##>

########################################
clear-host
$ErrorActionPreference = "Stop"
$start = get-date
write-host "StartTime: "  $start

### End
########################################
$Counting = 0
$pathDir = "C:\temp\"
$filedate = (Get-Date).tostring(“yyyyMMdd_HHmmss”)

### CSV output
$filename = $pathDir + 'MemoryReport_' + $filedate + '.log'

### Instance Declaration or Serverlist file declarion
########################################
$Instance = "EUDVMMSSQL205\SEKO077P"

## OR ##
#$Instance= get-content C:\Serverslist.txt
########################################

### Version details script
########################################
$Ver_Opt = "select substring(convert(varchar,(SERVERPROPERTY('Productversion'))),1,2)"

### Query for 2008R2 versions below
########################################
$SqlQuery1 = "SELECT	CAST( SERVERPROPERTY('MachineName') AS NVARCHAR(128)) AS [MachineName],
		cast(isnull(SERVERPROPERTY('InstanceName'),'Default') as nvarchar) as InstanceName,
		serverproperty('edition') as [Edition],
		serverproperty('productlevel') as [Servicepack],
		SERVERPROPERTY('Productversion') AS [ProductVersion],
		(cntr_value/1024) as MemoryInMB,
			(SELECT CAST( ((SUM(CAST( mf.size AS BIGINT ))* 8) / 1024.0) AS DECIMAL(18,2) ) AS Size_GBs
				FROM sys.master_files mf INNER JOIN sys.databases d ON d.database_id = mf.database_id
			WHERE d.database_id > 4) as SumOfDBsSize,
		(select count(name)as NumOfUserDBs from sys.databases where 
				name not in ('master','tempdb', 'msdb','model','sqladmin','distribution'))as UserDBsCount,
		(select CEILING((physical_memory_in_bytes/1048576.0)) from sys.dm_os_sys_info)as OsMemory 
FROM sys.dm_os_performance_counters 
WHERE counter_name IN ('Target Server Memory (KB)')"

### Query for Higher verisons like 2012,2014
########################################
$SqlQuery2 = "SELECT	CAST( SERVERPROPERTY('MachineName') AS NVARCHAR(128)) AS [MachineName],
		cast(isnull(SERVERPROPERTY('InstanceName'),'Default') as nvarchar) as InstanceName,
		serverproperty('edition') as [Edition],
		serverproperty('productlevel') as [Servicepack],
		SERVERPROPERTY('Productversion') AS [ProductVersion],
		(cntr_value/1024) as MemoryInMB,
			(SELECT CAST( ((SUM(CAST( mf.size AS BIGINT ))* 8) / 1024.0) AS DECIMAL(18,2) ) AS Size_GBs
				FROM sys.master_files mf INNER JOIN sys.databases d ON d.database_id = mf.database_id
			WHERE d.database_id > 4) as SumOfDBsSize,
		(select count(name)as NumOfUserDBs from sys.databases where 
				name not in ('master','tempdb', 'msdb','model','sqladmin','distribution'))as UserDBsCount,
		(select CEILING((physical_memory_kb/1048576.0)) from sys.dm_os_sys_info)as OsMemory 
FROM sys.dm_os_performance_counters 
WHERE counter_name IN ('Target Server Memory (KB)')"

### Looping for listed servers
########################################

foreach($In in $Instance)
{
$Counting = $Counting + 1
### Try block start
try
{
### Snapings sql modules
#######################################
asnp SqlServer* -ea 0

$Ver = Invoke-Sqlcmd -ServerInstance $In -Query $Ver_Opt

### Condtion for the different versions
if ($Ver[0] -eq 10) 
{
### CSV output
Invoke-Sqlcmd -ServerInstance $In -Query $SqlQuery1 |select-object MachineName,InstanceName,Edition,ServicePack,ProductVersion,MemoryInMB,SumOfDBsSize,UserDBsCount,OsMemory|`
ConvertTo-Csv -NoTypeInformation | Select-Object -Skip 1| Out-File  -Append $filename
## -Delimiter "," | Select-Object -Skip 1 | % {$_ -replace '"', ""} | Out-File  -Append $filename -Force -Encoding ascii
}
else 
{
### CSV Output
Invoke-Sqlcmd -ServerInstance $In -Query $SqlQuery2 |select-object MachineName,InstanceName,Edition,ServicePack,ProductVersion,MemoryInMB,SumOfDBsSize,UserDBsCount,OsMemory |`
ConvertTo-Csv -NoTypeInformation | Select-Object -Skip 1| Out-File  -Append $filename
}

} ### Try block ends
catch{ write-host -foregroundcolor magenta "****WARNING***** `n`nInstanceName : " $In `n"SQL Services are not in online status or May be Network Error or Instancename is not valid"}
} ### loop ends
### counting Number of Instances
$End = get-date
write-host "EndTime: "  $End
Write-host "Duration_Seconds :" (NEW-TIMESPAN –Start $start –End $End).Seconds
Write-host "Number of Instances :" $Counting

remove-variable Counting
remove-variable In
remove-variable start
remove-variable filename
remove-variable end
remove-variable Instance
remove-variable Ver_Opt
remove-variable ver
remove-variable pathDir
remove-variable SqlQuery2
remove-variable SqlQuery1

