Clear-host
$ErrorActionPreference='stop'

$a = "<style>"
$a = $a + "BODY{background-color:white;}"
$a = $a + "TABLE{border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;font:0.7em/145% Segoe UI,helvetica,Segoe UI,Segoe UI;}"
$a = $a + "TH{border-width: 1px;padding: 3px;border-style: solid;border-color: black;background-color:#778899}"
$a = $a + "TD{border-width: 1px;padding: 3px;border-style: solid;border-color: black;}"
$a = $a + "tr:nth-child(odd) { background-color:#d3d3d3;}"
$a = $a + "tr:nth-child(even) { background-color:white;}"
$a = $a + "</style>"

$colorTagTable = @{
                    Connected = ' style="color:Green"><strong>Connected</strong><';
                    DISCONNECTED = ' style="color:red"><strong>DISCONNECTED</strong><';
                    Unknown = ' style="color:yellow"><strong>Unknown</strong><';
                    SYNCHRONIZED  = ' style="color:Green"><strong>SYNCHRONIZED</strong><';
                    SYNCHRONIZING =' style="color:Green"><strong>SYNCHRONIZING</strong><';                               
                    PENDING_FAILOVER =' style="color:yellow"><strong>PENDING_FAILOVER</strong><';
                    SUSPENDED =' style="color:red"><strong>SUSPENDED</strong><';
                    UNSYNCHRONIZED =' style="color:Green"><strong>SYNCHRONIZED</strong><';
                    NULL =' style="color:Green"><strong>SYNCHRONIZED</strong><';
                   }

### Instance Declaration or Serverlist file declarion
########################################
#$Instance = get-content C:\HC\Srv.txt
$serversMirr = "InstanceName",""

$pathDir = "C:\Temp\"
$dt = get-date -format yyyyMMdd_HHmmss
$filedate = (Get-Date).tostring(“dd-MM-yyyy-Hmm”)
$filename = $pathDir + 'MirrorStatusReport_' + $filedate + '.html'

$Q1 = "SELECT (case mirroring_role_desc when 'principal' then @@servername  else mirroring_partner_instance end)AS PrincipalServer,
		(case mirroring_role_desc when 'mirror' then @@servername  else mirroring_partner_instance end )AS MirrorServerName,	
		mirroring_witness_name as WitnessServer, 
        DB_name(database_id) AS DatabaseName,mirroring_connection_timeout as Mirror_timeOut,
        mirroring_safety_level_desc as SafetyLevel,
         mirroring_state_desc AS MirroringStatus,        
        mirroring_witness_state_desc as WitnessStatus
        FROM sys.database_mirroring 
        WHERE mirroring_state is not NULL"

     
    foreach ($server in $serversMirr) {
        try {
            asnp SqlServer* -ea 0
            $cmd1 =Invoke-Sqlcmd -ServerInstance $server -query $Q1  |select-object PrincipalServer,MirrorServerName,WitnessServer,DatabaseName,SafetyLevel,MirroringStatus,WitnessStatus |` 
            convertto-html  -head $a -body "<H3><center><u> Database Mirroring Status Report: $filedate </center></U> </H3>"|Out-String
            
            $colorTagTable.Keys | foreach { $cmd1 = $cmd1 -replace ">$_<",($colorTagTable.$_) }
              #write-host $cmd1       
             $cmd1 | out-file -append $filename 
        }
        catch [System.Data.SqlClient.SqlException] {
         write-host "$server Server Not Found!" -ForegroundColor RED 
         Write-Host "Error Message: [$($_.Exception.Message)"] -ForegroundColor YELLOW
         Write-Output "$server Server Not Found!" | Out-File $pathDir + 'error_log.txt' -Append
         Write-output "$error[0].Exception" | Out-File $pathDir + 'error_log.txt' -Append
  
        }
    }
	
$fromaddress = "c1-cs-sql-alert@t-systems.com" 
$toaddress = "DL-TS-Delivery-SL-CSS-GDU-CCS-DB-OPS-SQL-MY@t-systems.com" 
$Subject = "Q4USC1SYS0158/Q4USC1SYS0148/MirroringReport"  
$smtpserver = "mail-c1.ts-na.mgt" 
$message = new-object System.Net.Mail.MailMessage
$message.From = $fromaddress
$message.To.Add($toaddress)
$message.IsBodyHtml = $True
$message.Subject = $Subject
If (-Not $filename.Length -eq 0){ $message.Attachments.Add($filename)}
$message.body = "Q4USC1SYS0158/Q4USC1SYS0148/MirroringReport"
$smtp = new-object Net.Mail.SmtpClient($smtpserver)
$smtp.Send($message)

	
	
### Variable removing
######################################################
remove-variable colorTagTable
remove-variable Q1
remove-variable filename
remove-variable serversMirr
remove-variable server
remove-variable cmd1