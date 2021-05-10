clear-host
$ErrorActionPreference = "continue"

## For multiple Servers 
#$servers = get-content C:\temp\srv.txt

## For single server
$servers = "CHMNTS25A","CHNVMMSAPP001"

## log file
$pathDir = "C:\temp\" 
$dt = get-date -format yyyyMMdd_HHmmss
$filedate = (Get-Date).tostring(“dd-MM-yyyy_HHmmss”)
$logfile = $pathDir + 'DBStartReport' + $filedate + '.log'

$Query1 = "select @@Servername as ServerName,name as DBName,state_desc as DB_Status,GETDATE() as Date 
from sys.databases where name not in ('master','tempdb', 'msdb','model','SQLADMIN')"

ForEach ($server in $servers) 
{ 

    try
    {
   # For all SQL Services
   #$instances = get-service -computerName $server -displayname *SQL* |`
   #Where-Object {$_.DisplayName -notlike '*Active Directory*' -and $_.DisplayName -notlike '*VSS Writer*' }

   ## Only SQL and Agent services
   $instances = get-service -computerName $server |where-object {$_.Name -like 'MSSQL$*' -OR $_.Name -like 'SQLAgent$*'}   

   Echo "****Before******/// ServerName: $server" >>$logfile
   Echo "****Before******/// ServerName: $server"
   Echo $instances  >> $logfile
   Echo $instances

   echo " "
   echo "Starting the services" >>$logfile
   echo "Starting the services"
   $instances | Where-Object {$_.status -eq "Stopped"} |start-service -confirm 
   
   echo " " >> $logfile
   echo " "
   Echo "****After******/// ServerName: $server" >> $logfile
   Echo "****After******/// ServerName: $server"
   echo " " >> $logfile
   echo " "
   Echo $instances >> $logfile
   Echo $instances
  }
   catch{ write-host -foregroundcolor Yellow "****WARNING***** `n`nInstanceName :" $server `
   `n" This service may be disable already/stopped due to that unable to bring online 'n "}
    
    #################################################
    ## This part is required after starting the service only 
   try{
            if (!$?) {
            Echo "$server - No SQL instance found" >> $logfile
            }
            Else {
                 ForEach ($instance in $instances) {
                    if (($instance.name -eq "MSSQLSERVER") -or ($instance.name -like "MSSQL$*")) {
                    # Echo "$server, $($instance.name)" >> $logfile

                        $I = $Instance.name.Split("$")
	                    $S = $server + "\" + $I[1]
                        
                                          
                        Echo "Database status " >>$logfile
                        write-host " "
                        Echo "Database status " 
                        asnp SqlServer* -ea 0
                        Invoke-Sqlcmd -ServerInstance $S -Query $Query1 >> $logfile 
                        Invoke-Sqlcmd -ServerInstance $S -Query $Query1 |ft -autosize                  
                        }
                    }    
                }
    }
catch{ write-host -foregroundcolor Yellow "****WARNING***** `n`nInstanceName :" $S `
`n"SQL Services are not in online status or May be Network Error or Instancename is not valid`n`n"}

}



