Remove-Item -Path C:\temp\P2P-CleanUpJob\Log\* -Include LogReport_*.log -ErrorAction SilentlyContinue

Clear-host
$ErrorActionPreference = "stop"
$start = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$Counting = 0
$RetentionDays = 5
$countingfiles = 0
$countingfiles1 = 0
$size1 = 0
$size = 0
$Date = Get-Date -Format ddMMyyy-hhmmss
$Path = "C:\temp\P2P-CleanUpJob\"
$folders = get-content C:\temp\P2P-CleanUpJob\FilesPath.txt
#$folders = "\\kscmssos01\FSSC\P2P\BW_PRO_IMM\ZKOF_Autobackup"
$InputLines = ($folders| Measure-Object –Line).lines
$logFile = $Path + "Log\LogReport_" + $Date + ".log" 
$errorlog = $Path + "Log\ErrorLogFile_" + $Date + ".log" 
"### START TIME "+ $(Get-Date -Format "yyyy-MM-dd HH:mm:ss") + " ###" | Out-File -FilePath $logFile
" " | Out-File -FilePath $logFile -Append
" " | Out-File -FilePath $logFile -Append


foreach ($file in $folders )
{
    $Counting += 1

    ### working status
    Write-Progress -Activity "$Counting. WORK with input data" -status "Working on row $Counting" `
    -percentComplete (($Counting -1) / $InputLines * 100)

    try{


     ### Script block

    $countingfiles =  Get-ChildItem $file -recurse -Include *.pdf,*.txt  -Exclude "$RECYCLE.BIN\*" -ErrorAction Continue |`
    where {$_.lastwritetime -lt (get-date).adddays(-$RetentionDays)} 

    $countingfiles | Out-File -FilePath $logFile -Append

    $countingfiles = $countingfiles.count 
      
    $size = ((Get-ChildItem $file -recurse | Measure-Object -Property length -sum).sum)/1MB

 "*** Folder path Path ***  Number of files  *** Folder size ***" | Out-File -FilePath  $logFile -Append
 "$file ; $countingfiles ; $size " | Out-File -FilePath $logFile -Append
  
      
    #Remove-Item $Ctxt
    }
 
    catch
    { 
        $error = $_.Exception.Message
        "### Error ### " + $file + $date + $error | out-file -append $errorlog
    }

    $countingfiles1 += $countingfiles
    $size1 += $size

  }
#$Date = Get-Date -Format ddMMyyy-hhmmss
#$Path = "C:\temp\P2P-CleanUpJob\"
#$logFile = $Path + "ErrorLogFile_" + $Date + ".log" 
#"### START # "+ $(Get-Date -Format "yyyy-MM-dd HH:mm:ss") + " ###" | Out-File -FilePath $logFile -Append
#"Number of Files : ($Ctxt).count " |Out-File -FilePath $logFile -Append

$End =Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$duration = (NEW-TIMESPAN –Start $start –End $End).Seconds
" " | Out-File -FilePath $logFile -Append
" " | Out-File -FilePath $logFile -Append
"### Duration of the script ### "  + $duration  | Out-File -FilePath $logFile -Append
"### Number of shared folders ### " + $Counting | Out-File -FilePath $logFile -Append
"### Number of files in all folders " + $countingfiles1  | Out-File -FilePath $logFile -Append
"### Size of the files ### " + $size1 | Out-File -FilePath $logFile -Append
"### END TIME "+ $(Get-Date -Format "yyyy-MM-dd HH:mm:ss") + " ###" | Out-File -FilePath $logFile -Append

<#

$htmllist = "<!DOCTYPE html>"
$htmllist += "<html><head><style>div{ background-color: lightgrey; font-family:Tahoma; font-size:8pt; width: 100px;  border: 2px solid black;  padding: 5px;  margin: 1px;}</style></head>"
$htmllist += "<body><h2>Clean-UP Job Report</h2>"
$htmllist += "<div>Report Date : $End <br>Varsion : 1.0 <br>DurationInSec: $Duration <br>Number of share paths : $Counting <br>Number of removed files : $nfiles  </div>" 
$htmllist += "</body></html>"

## Email setting
$fromaddress = "tsy_abazar@konenet.com" 
#$toaddress = "FMB-TS-Delivery-SL-CSS-DB-OPS-SQL@t-systems.com"
$toaddress = "Ashok-Sagar.Bazar@t-systems.com"
$Subject = "<<<Automatic Report >>> Clean-UP Job Report"  
$smtpserver = "eudsmtp.konenet.com" 
$message = new-object System.Net.Mail.MailMessage
$message.From = $fromaddress
$message.To.Add($toaddress)
$message.IsBodyHtml = $True
$message.Subject = $Subject
If (-Not $logFile.Length -eq 0){ $message.Attachments.Add($logFile)}
#$message.body = "Capacity Report Monthly"
$message.Body = $message.Body + $htmllist
$smtp = new-object Net.Mail.SmtpClient($smtpserver)
$smtp.Send($message)

#>