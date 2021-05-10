<#

To find dedicatd and shared servers information with names

        ServerName, ServerType, InstanceCount, InstanceNames
        Version 1.0
        Date 04/12/2019
        Script : Ashok
        Support SQL Version : 2005 and higher

#>

## Variables declaration
Clear-Host
$ErrorActionPreference = "Stop"
$pathDir = "D:\DATA\SQL_Support\DBA\DBA_Automation\EUDVMMSSQL100_AutoJobs\DedicatedServers\"
$hostname = $env:COMPUTERNAME
$filedate = (Get-Date).tostring(“dd-MM-yyyy__hhmmss”)
$filename = $pathDir + 'ServerStatus_' + $filedate + '.log'
$errorlog = $pathDir + 'ErrorLog_' + $filedate + '.log'
$InputFile = $pathDir + "Instances.txt"
$scriptFile = $pathDir + "serversinfo.sql"
$cleanpath = $pathDir + '*'
Remove-Item –path $cleanpath -include ServerStatus*.log, ErrorLog*.log -ErrorAction Ignore
$Counting = 0
$OldInstanceName = " "

$InstanceName = get-content $InputFile
#$InstanceName = "EUDVMMSSQL100\INS10","EUDVMMSSQL100\INS01" 


## Looping start
###################################################
foreach($InsNames in $InstanceName)
{
asnp SqlServer* -ea 0
$Counting = $Counting + 1


    ## Try block Begin
            $InsNamesNew = $InsNames
            $Instance = $InsNames.Split("\")
            $ServerName = $Instance[0]
            
     
     if ($OldInstanceName -ne $ServerName){
  ### CSV Output
        
        Invoke-Sqlcmd -ServerInstance $InsNamesNew -InputFile $scriptFile |` 
        select-object ServerName,InstanceType,InstanceCount,InstanceNames|`
        ConvertTo-Csv -NoTypeInformation | Select-Object -Skip 1 |Out-File  -Append $filename
        $OldInstanceName = $ServerName

        }    
      
    



## Catch block End

} ## Looping End


