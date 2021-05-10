clear-host
$ErrorActionPreference = "continue"

## For multiple Servers 
#$servers = get-content C:\temp\srv.txt

## For single server
$servers = "CHMNTS25A","CHNVMMSAPP001"


## log file
$pathDir = "C:\temp\" 
$filedate = (Get-Date).tostring(“dd-MM-yyyy_HHmmss”)
$logfile = $pathDir + 'DBStopReport' + $filedate + '.log'


ForEach ($server in $servers) 
{ 
   try{

   #$instances = get-service -computerName $server -displayname *SQL* |`
   #Where-Object {$_.DisplayName -notlike '*Active Directory*' -and $_.DisplayName -notlike '*VSS Writer*' }   

    ## SQL Services and SQL Agent services only
    $instances = get-service -computerName $server |where-object {$_.Name -like 'MSSQL$*' -OR $_.Name -like 'SQLAgent$*'}
   

   Echo "****Before******/// ServerName: $server" >>$logfile
   Echo "****Before******/// ServerName: $server"
   Echo $instances  >> $logfile
   Echo $instances

   ## Choose any one of the below command for to stop or start services
   
   echo "+++++++ Stopping the services ++++++++++" >>$logfile
   echo "+++++++ Stopping the services ++++++++++"
   $instances | Where-Object {$_.status -eq "Running"} |Stop-Service -confirm -force

   
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
   `n"SQL Services are not in online status or May be Network Error or Instancename is not valid`n`n"}

}



