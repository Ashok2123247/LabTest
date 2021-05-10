This script has the following functionalities:

#1. Takes imput from a text file (Containing list of server / Computer names)
#2. Calculates free disk space of all servers / computers on the text file
#3. Returns only servers / Computers with % free disks space less than or equal to 10%
#4. Exports the info to a CSV file
#5. If you wish to schedule this script to run automatically, see my blog post How to schedule a PowerShell Script to auto run on a Windows Server

#6. Sends a copy of the CSV report to you if you configure #5 above

 Required / Recommended

1. You will need a PowerShell script editor to edit this script and customize it for your use. I recommend PowerShell ISE.

2. If you want to send report, you will require the exchange PowerShell module, Exchange.ps1.
=========================================================================================================================================
$DiskReport = ForEach ($Servernames in ($File))  
 
{Get-WmiObject win32_logicaldisk <#-Credential $RunAccount#> ` 
-ComputerName $Servernames -Filter "Drivetype=3" ` 
-ErrorAction SilentlyContinue |  
 
#return only disks with 
#free space less   
#than or equal to 0.1 (10%) 
 
Where-Object {   ($_.freespace/$_.size) -le '0.1'} 
 
}  
 
 
#create reports 
 
$DiskReport |  
 
Select-Object @{Label = "6.64.7.185";Expression = {$_.SystemName}}, 
@{Label = "Drive Letter";Expression = {$_.DeviceID}}, 
@{Label = "Total Capacity (GB)";Expression = {"{0:N1}" -f( $_.Size / 1gb)}}, 
@{Label = "Free Space (GB)";Expression = {"{0:N1}" -f( $_.Freespace / 1gb ) }}, 
@{Label = 'Free Space (%)'; Expression = {"{0:P0}" -f ($_.freespace/$_.size)}} | 
 
#Export report to CSV file (Disk Report) 
 
Export-Csv -path "\\Servername\ServerStorageReport\DiskReport\DiskReport_$logDate.csv" -NoTypeInformation 
 
 
 
#Send disk report using the exchange email module 
 
 
Import-Module "\\Servername\ServerStorageReport\ExchangeModule\Exchange.ps1" -ErrorAction SilentlyContinue 
 
# Attach and send CSV report (Most recent report will be attached) 
 
$messageParameters = @{                         
                Subject = "Weekly Server Storage Report"                         
                Body = "Attached is Weekly Server Storage Report. The scipt has been amended to return only servers with free disk space less than or equal to 10%. All reports are located in \\Servername\ServerStorageReport\DiskReport\, but the most recent  is sent weekly"                    
                From = "Email name1 <Email.name1@domainname.com>"                         
                To = "Email name1 <Email.name1@domainname.com>" 
                CC = "Email name2 <Email.name2@domainname.com>" 
                Attachments = (Get-ChildItem \\Servername\ServerStorageReport\DiskReport\*.* | sort LastWriteTime | select -last 1)                    
                SmtpServer = "SMTPServerName.com"                         
            }    
Send-MailMessage @messageParameters -BodyAsHtml  