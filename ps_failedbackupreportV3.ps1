## Script for to find the Failed Backup Jobs status
## Input values
## version 3.1
## Ashok Sagar 
######################################################################################
 
#Set-StrictMode -Version 3.0


## Variables declaration
Clear-Host
$ErrorActionPreference = "Stop"
$pathDir = "D:\DATA\SQL_Support\DBA\DBA_Automation\EUDVMMSSQL100_AutoJobs\FailedBackup\"
$start = (get-date -DisplayHint DateTime).DateTime
$Counting = 0
$hostname = $env:COMPUTERNAME
$filedate = (Get-Date).tostring(“dd-MM-yyyy_hh-mm-ss”)
$filename = $pathDir + 'FailedBackupJobsReport_' + $filedate + '.html'
$errorlog = $pathDir + 'ErrorLog_' + $filedate + '.log'
$InputFile = $pathDir + "Instances.txt"
$scriptFile = $pathDir + "SQLQuery2.sql"
$cleanpath = $pathDir + '*'
Remove-Item –path $cleanpath -include FailedBackupJobsReport*.html, ErrorLog*.log -ErrorAction Ignore

## CSS Block

$a = @'
<style>body{background-color:#2F4F4F;}
.container{	width:90%; margin:auto; margin-top: 35px;background-color: #FFFAFA;overflow:hidden; box-shadow: 5px 10px }
.headerbox {width:auto%; padding-left:10px;padding-right:10px;padding-top:5px;padding-bottom:0px; }
.p.a{font:0.4em/145% Segoe UI;font-style: oblique;}
.TABLE1{width:auto%;font:0.7em/145% Segoe UI,helvetica,Segoe UI,Segoe UI;}
.headerbox.h1{font-family:Castellar;padding-bottom:0px}
.datacon{color:#E0FFFF;width:auto%;background-color :#008B8B;padding:20px;}
.databox {color:#E0FFFF;width:auto%;background-color :#008B8B;}
.databox.h3{color:#E0FFFF;font-family :Castellar;line-height: normal; }
TABLE{width:100%;border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;font:0.6em/145% Segoe UI,helvetica,Segoe UI,Segoe UI;}
TH{border-width: 1px;padding: 3px;border-style: solid;border-color: black;background-color:#778899}
TD{border-width: 1px;padding: 3px;border-style: solid;border-color: black;}
tr:nth-child(odd) { background-color:#F2F2F2;}
tr:nth-child(even) { background-color:#DDDDDD;}
</style>
'@

$colorTagTable = @{
                    NO_BACKUP = ' style ="color:RED"><strong>There is no backup since last 24 hours</strong><';
                    NO_HISTORY = ' style ="color:RED"><strong>There is no backup history for this DB, JOB NOT EXISTED </strong><';                    
                  }



## Input values from text file

$servernames = get-content $InputFile
#$servernames = "EUDVMMSSQL100\INS10","EUDVMMSSQL203\SEKO027P"

$InputLines = ($servernames).Count

$a =  $a + '<div class="container"> <div class ="headerbox"><h1>SQL Server Backup Report</h1><div class = "table1">Date: ' + $start + ' || Version : 3.0  || Source server : ' + $hostname + '</div></div>'| Out-File -append $filename

$a =  $a + '<div class = "datacon">' | Out-File -append $filename

"START TIME " + "    " +  $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")| Out-File -FilePath $errorlog -Append
" "| Out-File -FilePath $errorlog -Append

foreach($instance in $servernames)
{
asnp SqlServer* -ea 0

$Counting += 1

Write-Progress -Activity "$Counting >> Working on $instance ...."  -percentComplete (($Counting) / $InputLines * 100)
      
 try{
     
    $html = Invoke-Sqlcmd -ServerInstance $instance -InputFile $scriptFile -ErrorAction Ignore |`
    select-object ServerName,Database_name,RMode,BackupFinishDate,backup_type,BackupDue,BackupStatus |`
    ConvertTo-HTML  -head '<div class = "databox" > ' $a '</div>' | out-string     
    $html | foreach {$html = $html -replace "(?sm)<table>\s+</table>"}
    $colorTagTable.Keys | foreach {$html = $html -replace ">$_<",($colorTagTable.$_) }

    "PING [OK]" + "  >>>    " + $instance | Out-File -FilePath $errorlog -Append

    $html | out-file -Append $filename
}
catch
{ 

"PING [NOT OK]" + "  >>>    " + $instance | Out-File -FilePath $errorlog -Append
 write-host "PING [NOT OK] >>" -ForegroundColor Magenta $instance 

}

}
" "| Out-File -FilePath $errorlog -Append
"END TIME" + "    " +  $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")| Out-File -FilePath $errorlog -Append

#$red = "color:RED"
#$red += ">"
$End = get-date
$Duration = (NEW-TIMESPAN –Start $start –End $End).Seconds

$htmllist = "<!DOCTYPE html>"
$htmllist += "<html><head><style>div{ background-color: lightgrey; font-family:Tahoma; font-size:8pt; width: 100px;  border: 2px solid black;  padding: 5px;  margin: 1px;}</style></head>"
$htmllist += "<body><h2>Report Summary</h2>"
$htmllist += "<div>Report Server : $hostname <br>Report Date : $END <br>Version : 3.1 <br>DurationInSec: $Duration <br>Number of Servers : $Counting </div>" 
#$htmllist += "<div><p style= $red Failure backups : $redcolor <br> Database without job : $redcolor1</div>"
$htmllist += "</body></html>"
$fromaddress = "tsy_abazar@konenet.com" 
$toaddress = "FMB-TS-Delivery-SL-CSS-DB-OPS-SQL@t-systems.com"
#$toaddress = "Ashok-Sagar.Bazar@t-systems.com"
$Subject = "DATABASE BACKUP FAIL REPORT"  
$smtpserver = "eudsmtp.konenet.com" 
$message = new-object System.Net.Mail.MailMessage
$message.From = $fromaddress
$message.To.Add($toaddress)
$message.IsBodyHtml = $True
$message.Subject = $Subject
If (-Not $filename.Length -eq 0){ $message.Attachments.Add($filename)
$message.Attachments.Add($errorlog)}
$message.body = " "
$message.Body = $message.Body + $htmllist
$smtp = new-object Net.Mail.SmtpClient($smtpserver)
$smtp.Send($message)

