## Automate Decommission Script for KONE Servers
## Author Ashok Sagar
## Date : 29/12/2018
## Must use PowerShell version 3.0 or higher version
##############################################################################

## Variable declaration 
clear-host
$ErrorActionPreference = "Stop"
[void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO')
[void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMOExtended') 
asnp SqlServer* -ea 0
$InstanceName = "EUDVMMSTEST100"
#$InstanceName = read-host "Enter Instance Name >>>"
$date = Get-Date -Format ddMMyyyy-hhmmss 
$filedate = (Get-Date).tostring(“dd-MM-yyyy_HHmmss”)
$line = "=" * 91
$space = " " * 8
$InstanceName = New-Object Microsoft.SqlServer.Management.Smo.Server $InstanceName 
$MachineName = ($InstanceName).netname
$Instance = ($InstanceName).InstanceName
if($Instance.Length -eq 0) {$Instance1 = 'MSSQLSERVER'}
$BackupPath = ($InstanceName).BackupDirectory + "\"
if( -not $Databaselist) { $Databaselist = (($InstanceName).Databases).Name -ne "tempdb"}
$Loginslist = "SELECT name FROM sys.syslogins WHERE NAME LIKE 'HPSam_User'or name like 'Tivoli_User'"
$Loginslist = Invoke-Sqlcmd -ServerInstance $InstanceName.Name -Query $Loginslist -Database "master"
$BackupInfo = "select name from msdb.dbo.sysjobs where name like 'App DB Maint%' or name like 'SSI -%'"
$BackupInfo = Invoke-Sqlcmd  -ServerInstance $InstanceName.Name -Query $BackupInfo -Database "msdb"


## Display Report
Clear-host
write-host "*********************************** Decommission Report ***********************************" -ForegroundColor Yellow
write-host " "
write-host "Server Name        :" ($InstanceName).NetName
write-host "Instance Name      :" $Instance1
write-host "Date               :" (Get-Date).DateTime
write-host "Product            :" ($InstanceName).Product
write-host "Product Version    :" ($InstanceName).Version
write-host $line

write-host "Database backup is in progress.. (FULL)"
foreach ($Database in $Databaselist)
{
                  
                    if($Database -ne $null) 
					{	
                        try{
                        $DB = $Database
                        $BackupPath = "\\"+$MachineName +"\" + ($InstanceName).BackupDirectory + "\"  -replace ":","$"
                        $SubQuery = "BACKUP DATABASE [" + $DB + "] TO DISK = N'" + $BackupPath + $DB + "_FULL_"+ $date + ".bak' with compression;"
                        Invoke-Sqlcmd  -ServerInstance $InstanceName.Name -Query $SubQuery -ErrorAction Ignore
                                                
                        ## Backup Verfy from the Backup path
                        $Status = $DB + "_FULL_"+ $date + ".bak"                                                                       
                                                                     
                        If ($Status -ne 0 -and $Status -ne $null) 
                        {write-host $space "Backup Done on " $DB -ForegroundColor green } 
                        else {write-host $space $DB  "NOT DONE" -ForegroundColor RED }           
                        }catch{write-host "Backup got error please check again.." }                 
                                             
					}#if ends
					else { write-host "Enter correct database name/Database is not existed" -ForegroundColor RED }
                    
                                
}

## TSMY Maintenace Jobs Deletion

write-host "TSMY Maintenance Jobs Deletion in progress.."
foreach($jobinfo in $BackupInfo.name)
{

    If($jobInfo -ne 0 -and $jobinfo -ne $null)
    {
    try{
    $JobQ = "exec sp_delete_job @job_name = " + "'" + $jobinfo +"'"

    Invoke-Sqlcmd -ServerInstance $InstanceName.Name -Query $JobQ -Database 'msdb'
    write-host $space "Job Deleted " $jobInfo -ForegroundColor Green 
    }catch{write-host "TSMY Maintenance Jobs Deletion got error please check again.." } 
    }
    else { Write-host "No Jobs found" -ForegroundColor Red}
}


## Remove Monitoring Logins 
write-host "Remove Monitoring Logins in progress.."
foreach($LoginsInfo in $Loginslist.name)
{ 
    If($LoginsInfo -ne 0 -and $LoginsInfo -ne $null)
    {
    try{
    $Drop = "DROP LOGIN [" + $LoginsInfo + "]"

    Invoke-Sqlcmd  -ServerInstance $InstanceName.Name -Query $Drop -Database "master" 
    write-host $space "Login Deleted " $LoginsInfo -ForegroundColor Green
     }catch{write-host "Remove Monitoring Logins got error please check again.." } 
    }
}

write-host "SQLADMIN Database Deletion in progress.."
foreach($db in $Databaselist)
{ 
    If($db -eq 'SQLADMIN')
    {
    try{
    $Drop = "DROP DATABASE [" + $db + "]"
    Invoke-Sqlcmd  -ServerInstance $InstanceName.Name -Query $Drop
    write-host $space "Database Deleted " $db -ForegroundColor Green
    }catch{write-host "SQLADMIN Database Deletion got error or DB in use... please check again.." -ForegroundColor Magenta } 
    
    }
}

write-host "Start-up mode change in progress.."

#$InstanceName = "EUDVMMSTEST100\TEST"
#$InstanceName = New-Object Microsoft.SqlServer.Management.Smo.Server $InstanceName 
#$MachineName = ($InstanceName).netname
#$Instance = ($InstanceName).InstanceName
try{
if($Instance.Length -eq 0){
## to set the services on Disable mode
get-service -computerName $MachineName | where-object {$_.name -like 'MSSQLSERVER' -OR $_.Name -like 'SQLSERVERAGENT'}|`
set-service -Startup disable
write-host $space "Startup Mode Changed to Disable on " $Instance -ForegroundColor Green
}else {
get-service -computerName $MachineName | where-object {$_.name -like 'MSSQL$' + $Instance -OR $_.Name -like 'SQLAgent$' + $Instance}|`
set-service -Startup disable
write-host $space "Startup Mode Changed to Disable on " $Instance -ForegroundColor Green
}
}catch{write-host "Start-up mode change got error.. Please check again.."}

write-host "Shutdown the DB is in progress.."
try{
if($Instance.Length -eq 0){
## to set the services on Disable mode
get-service -computerName $MachineName | where-object {$_.name -like 'MSSQLSERVER' -OR $_.Name -like 'SQLSERVERAGENT'}|`
stop-Service -confirm -Force
write-host $space "Shutdown the DB " $Instance -ForegroundColor Green
}else {
get-service -computerName $MachineName | where-object {$_.name -like 'MSSQL$' + $Instance -OR $_.Name -like 'SQLAgent$' + $Instance}|`
stop-Service -confirm -Force
write-host $space "Shutdown the DB" $Instance -ForegroundColor Green
}
}catch{write-host "Shutdown the DB got error.. Please check again.."}

write-host "*********************************** Report END ********************************************" -ForegroundColor Yellow
