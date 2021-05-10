## Remove Old files
Remove-Item -Path C:\temp\P2P-CleanUpJob\Log\* -Include LogReport_*.log -ErrorAction SilentlyContinue

## Variable declaration
Clear-host
$start =Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$ErrorActionPreference = "stop"
$RetentionDays = 15
$CountingOuterLoop = 0
$CountingInnerLoop = 0
$countFolderFiles = 0
$CountTotalFiles = 0
$TotalFolderSize = 0
$FolderSize = 0
$Date = Get-Date -Format ddMMyyy-hhmmss
$SourcePath = "C:\temp\P2P-CleanUpJob\"
$logFile = $SourcePath + "Log\LogReport_" + $Date + ".log" 
$errorlog = $SourcePath + "Log\ErrorLogFile_" + $Date + ".log"

## Input file

#$FSfolders = get-content C:\temp\P2P-CleanUpJob\FilesPath.txt
$FSfolders = "\\kscmssos01\FSSC\P2P\BW_PRO_IMM\ZKOF_Autobackup","\\kscmssos01\FSSC\P2P\BW_TEST_S34\ZKOF_Autobackup","\\kscmssos01\FSSC\P2P\BW_TEST_IND\ZKOF_Autobackup"

## Measure counts
$InputLines = ($FSfolders| Measure-Object –Line).lines
 

## Script start
"<<< START TIME ::  "+ $(Get-Date -Format "yyyy-MM-dd HH:mm:ss") + " >>>" | Out-File -FilePath $logFile -Append
"================================================================================================" | Out-File -FilePath $logFile -Append

## Outer loop Looping start
foreach ($file in $FSfolders )
{
    $CountingOuterLoop += 1

    ### working status
    Write-Progress -Activity "Workign with " -status "Current row number $CountingOuterLoop" `
    -percentComplete (($CountingOuterLoop) / $InputLines * 100) -CurrentOperation Outerloop

    try{

     ### Script block

    $countFolderFiles =  Get-ChildItem $file -recurse -Include *.pdf,*.txt  -Exclude "$RECYCLE.BIN\*" -ErrorAction Continue |`
    where {$_.lastwritetime -lt (get-date).adddays(-$RetentionDays)} 
    
    $countFolderFiles  | Out-File -FilePath $logFile -Append
       
    $countFolderFiles = $countFolderFiles.count 

    $FolderSize = ((Get-ChildItem $file -recurse | Measure-Object -Property length -sum).sum)/1MB

"================================================================================================" | Out-File -FilePath $logFile -Append
    "## Folder path Path                  ## Number of files  ## Folder size in MB   " | Out-File -FilePath  $logFile -Append
    " " | Out-File -FilePath $logFile -Append
    "$file ; $countFolderFiles ; $FolderSize " | Out-File -FilePath $logFile -Append
"================================================================================================" | Out-File -FilePath $logFile -Append
    
       
    ### Remove Files block
     
    #Remove-Item $Ctxt
    
    }
 
    catch
    { 
        $error = $($_.Exception.Message)
        "<<< " + $file + $date + $error | out-file -append $errorlog
    }

    $CountTotalFiles += $countFolderFiles
    $TotalFolderSize += $FolderSize

  }
#$Date = Get-Date -Format ddMMyyy-hhmmss
#$Path = "C:\temp\P2P-CleanUpJob\"
#$logFile = $Path + "ErrorLogFile_" + $Date + ".log" 
#"### START # "+ $(Get-Date -Format "yyyy-MM-dd HH:mm:ss") + " ###" | Out-File -FilePath $logFile -Append
#"Number of Files : ($Ctxt).count " |Out-File -FilePath $logFile -Append

$End =Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$duration = (NEW-TIMESPAN –Start $start –End $End).Seconds
" " | Out-File -FilePath $logFile -Append
" #### REPORT SUMMARY ####  " | Out-File -FilePath $logFile -Append
"================================================================================================" | Out-File -FilePath $logFile -Append
"Duration of the script            >>> "  + $duration | Out-File -FilePath $logFile -Append
"Number of shared folders          >>> "  + $CountingOuterLoop | Out-File -FilePath $logFile -Append
"Total files count                 >>> "  + $CountTotalFiles | Out-File -FilePath $logFile -Append
"Total file shares size            >>> "  + $TotalFolderSize | Out-File -FilePath $logFile -Append
" " | Out-File -FilePath $logFile -Append
"================================================================================================" | Out-File -FilePath $logFile -Append
"<<< END TIME  :: "+ $(Get-Date -Format "yyyy-MM-dd HH:mm:ss") + " >>> " | Out-File -FilePath $logFile -Append


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