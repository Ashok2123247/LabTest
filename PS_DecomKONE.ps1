## Automate Decommission Script for KONE Servers
## Version 1
## Author Ashok Sagar
## Date : 29/12/2018
## Must use PowerShell version 3.0 or higher version
##############################################################################

## Variable declaration 
clear-host
Set-StrictMode -Version 3.0
$ErrorActionPreference = "Stop"
[void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO')
[void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMOExtended') 
asnp SqlServer* -ea 0
#$InstanceName = "EUDVMMSSQL100\INS10"
$InstanceName = read-host "Enter Instance Name >>>"
$date = Get-Date -Format ddMMyyyy-hhmmss 
$filedate = (Get-Date).tostring(“dd-MM-yyyy_HHmmss”)
$line = "=" * 91
$space = " " * 8
$InstanceName = New-Object Microsoft.SqlServer.Management.Smo.Server $InstanceName 
$MachineName = ($InstanceName).netname
$Instance = ($InstanceName).InstanceName              
$BackupPath = ($InstanceName).BackupDirectory + "\"
$Databaselist = (($InstanceName).Databases).Name -ne "tempdb"
$Loginslist = "SELECT name FROM sys.syslogins WHERE NAME LIKE 'HPSam_User'or name like 'Tivoli_User'"
$Loginslist =  Invoke-Sqlcmd  -ServerInstance $InstanceName -Query $Loginslist
$BackupInfo = "select name from msdb.dbo.sysjobs where name like 'App DB Maint%' or name like 'SSI -%'"
$BackupInfo = Invoke-Sqlcmd  -ServerInstance $InstanceName -Query $BackupInfo

## Display Report
Clear-host
write-host "*********************************** Decommission Report ***********************************" -ForegroundColor Yellow
write-host " "
write-host "Server Name        :" ($InstanceName).NetName
write-host "Instance Name      :" ($InstanceName).Name
write-host "Date               :" (Get-Date).DateTime
write-host "Product            :" ($InstanceName).Product
write-host "Product Version    :" ($InstanceName).Version
write-host $line

write-host "FULL Backup Report"
foreach ($Database in $Databaselist)
{

                    if($Database -ne $null) 
					{	
                        $DB = $Database
                        $BackupPath = "\\"+$MachineName +"\" + ($InstanceName).BackupDirectory + "\"  -replace ":","$"
                        $SubQuery = "BACKUP DATABASE [" + $DB + "] TO DISK = N'" + $BackupPath + $DB + "_FULL_"+ $date + ".bak' with compression;"
                        Invoke-Sqlcmd  -ServerInstance $InstanceName -Query $SubQuery
                                                
                        ## Backup Verfy from the Backup path
                        $Status = $DB + "_FULL_"+ $date + ".bak"                                                                       
                                                                     
                        If ($Status -ne 0 -and $Status -ne $null) 
                        {write-host $space "Backup Done on " $DB -ForegroundColor green } 
                        else {write-host $space $DB  "NOT DONE" -ForegroundColor RED }           
                                         
                                             
					}#if ends
					else { write-host "Enter correct database name/Database is not existed" -ForegroundColor RED }
                                
}

## TSMY Maintenace Jobs Deletion

write-host "TSMY Maintenance Jobs Deletion"
foreach($jobinfo in $BackupInfo)
{

    If($jobInfo -ne 0 -and $jobinfo -ne $null)
    {
    $JobQ = "exec sp_delete_job @job_name = " + $jobinfo
    #Invoke-Sqlcmd  -ServerInstance $InstanceName -Query  $JobQ
    write-host $space "Job Deleted " $jobInfo.name -ForegroundColor Green 

    }
    else { Write-host " No Jobs found" -ForegroundColor Red}
}

write-host "SQLADMIN Database Deletion"
foreach($db in $Databaselist){ 
If($db -eq 'SQLADMIN')
{
$Drop = "DROP DATABASE [" + $db + "]"
#Invoke-Sqlcmd  -ServerInstance $InstanceName -Query  $Drop -Database "master"
write-host $space "Database Deleted " $db -ForegroundColor Green
}
}


## Remove Monitoring Logins 
write-host "Remove Monitoring Logins"
foreach($LoginsInfo in $Loginslist){ 
    If($LoginsInfo -ne 0 -and $LoginsInfo -ne $null)
    {
    $Drop = "DROP LOGIN [" + $LoginsInfo.name + "]"
    #Invoke-Sqlcmd  -ServerInstance $InstanceName -Query $Drop -Database "master"
    write-host $space "Login Deleted " $LoginsInfo.name -ForegroundColor Green
    }
}

write-host "DB Shutdown"

## to set the services on Disable mode
get-service -computerName $ServerName |where-object {$_.Name -like 'MSSQL$'+ `
$Instance -OR $_.Name -like 'SQLAgent$'+ $Instance} | set-service -Startup disable
write-host $space "Startup Mode Changed to Disable on " $Instance -ForegroundColor Green

## to stop the Services on particular Instance
#get-service -computerName $ServerName |where-object {$_.Name -like 'MSSQL$'+`
#$Instance -OR $_.Name -like 'SQLAgent$'+ $Instance} | stop-Service -confirm -Force
write-host $space "Shutdown the Database Instance " $Instance -ForegroundColor Green 

write-host "*********************************** Report END ********************************************" -ForegroundColor Yellow

