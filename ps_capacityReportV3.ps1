### File name -- PS_CapacityReportDC.ps1
### Capacity Report Monthly
### Ashok Sagar 
### Varsion : v3.0
### Create Date : 11/03/2019
### Sourve Tables
<#
    dbo.CapacityReport_FinalData       //** Final Data **
    dbo.SourceTable                   //** DC and Location info **
    dbo.tlb_KCOFINT64_Accessdata     //** 2000 SQL version last access date **
    dbo.tlb_KCOFINT64_Data          //** 2000 SQL Final data **
#>
    
###################################################

clear-host
$Counting = 0
## Clean-up task
$pathDir = "D:\DATA\SQL_Support\DBA\Script\CapacityReport\DC\"
Remove-Item -Path $pathDir* -Include LogFile*.log, MonthlyCapacityReportCSV*.csv -ErrorAction SilentlyContinue;

$start = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$filedate = (Get-Date).tostring(“yyyyMMdd_HHmmss”)
$errorlog = $pathDir + 'LogFile_' + $filedate + '.log'
$export_csv = $pathDir + 'MonthlyCapacityReportCSV_' + $filedate + '.csv'
$hostInstance = "EUDVMMSSQL100\INS10"
$databasename = "CapacityReport"
### SQL Script files
$delete_rows = $pathDir + "DelterowsTable.sql"
$inputFile = $pathDir +  "CapacityReportScriptDC.sql"
$inputfile2000 = $pathDir + "CR_SQL2000V_DBCheckAll.sql"
$inputfile2000Access = $pathDir + "CR_SQL2000V_AccDate.sql"
$finalcollection = $pathDir + "Final2000Data.sql"
$finalScript = $pathDir + "CapacityFinalScriptDC.sql"
#$InputFile = $pathDir + "Servers1-DC.txt"

"### START # "+ $(Get-Date -Format "yyyy-MM-dd HH:mm:ss") + " ###" | Out-File -FilePath $errorlog -Append
## Delete the table rows
Invoke-Sqlcmd -ServerInstance $hostInstance -InputFile $delete_rows
Write-Debug "# Pre existing tables data deleted" |Out-File -FilePath $errorlog -Append

### Instance Declaration or Serverlist file declarion
########################################
#$ServerInstance = "EUDVMMSSQL100\INS10","EAPMSSQLKRD23Q","KCOFINT64"

$ServerInstance = get-content D:\DATA\SQL_Support\DBA\Script\CapacityReport\DC\Servers1-DC.txt
$InputLines= ($ServerInstance).Count

Function ErrorLog ($Logstring)
{
$msg = "## TIME :" + "$filedate " + ">>> " + "$Logstring"
Out-File -FilePath $errorlog -InputObject $msg -append
}


function fnSQLtabledatamain($tabledata)
{
#$hostInstance = "EUDVMMSSQL100\INS10"
#$databasename = "CapacityReport"
$table = '[dbo].[CapacityReport_FinalData]'

try
{
    foreach ($data in $tabledata)
    {

    ## Data Inserting to DB table
    $col1  = $data.'DC/LDR'
    $col2  = $data.'location'
    $col3  = $data.'ActiveNode/ServerName'
    $col4  = $data.'ClusterPair'
	$col5  = $data.'InstanceName'
	$col6  = $data.'DB_Name'
	$col7  = $data.'Status'
	$col8  = $data.'TotalSizeMB'
    $col9  = $data.'TotalSizeGB'
	$col10 = $data.'Last_SQL_Restart' 
	$col11 = $data.'User_Access_Activities(After Last SQL Restart)'
    $col12 = $data.'DateCheck'
	$col13 = $data.'Version'
    $col14 = $data.'Patch Number'
	$col15 = $data.'SP'
	$col16 = $data.'Status2'

    $TableDataIN =  " INSERT INTO $table ([DC/LDR],[location],[ActiveNode/ServerName],[ClusterPair],[InstanceName],[DB_Name],[Status],
                     [TotalSizeMB],[TotalSizeGB],[Last_SQL_Restart],[User_Access_Activities(After Last SQL Restart)],[DateCheck],[Version],
                     [Patch Number],[SP],[Status2])
                     VALUES ('$col1','$col2','$col3','$col4','$col5','$col6','$col7','$col8','$col9','$col10',
                     '$col11','$col12','$col13','$col14','$col15','$col16');"

    Invoke-Sqlcmd -ServerInstance $hostInstance -database $databasename -Query $TableDataIN
    
    }

 return "SUCCESS ## DC TABLE DATA" 
################## OUTPUT ################################    

#$Report | select-object 'DC/LDR',location,'ActiveNode/ServerName',ClusterPair,InstanceName,DB_Name,Status,TotalSizeMB,TotalSizeGB,Last_SQL_Restart,'User_Access_Activities(After Last SQL Restart)',DateCheck,Version,'Patch Number',SP,Status2 |`
#ConvertTo-Csv -NoTypeInformation | Select-Object -Skip 1| Out-File  -Append $filename1 
}
catch
{
        $err = $_.Exception.Message
		ErrorLog("Error: Unable to insert into SQL >> $err")
		eturn "ERROR >> DC TABLE DATA"
}

}

function fnSQLtabledata2000($tabledata2k)
{
#$hostInstance = "EUDVMMSSQL100\INS10"
#$databasename = "CapacityReport"
$table = '[dbo].[tlb_KCOFINT64_Data]'

try
{
    foreach ($data in $tabledata2k)
    {

    ## Data Inserting to DB table

    $col1  = $data.'DC/LDR'
    $col2  = $data.'location'
    $col3  = $data.'ActiveNode/ServerName'
    $col4  = $data.'ClusterPair'
	$col5  = $data.'InstanceName'
	$col6  = $data.'DB_Name'
	$col7  = $data.'Status'
	$col8  = $data.'TotalSizeMB'
    $col9  = $data.'TotalSizeGB'
	$col10 = $data.'Last_SQL_Restart' 
	$col12 = $data.'DateCheck'
	$col13 = $data.'Version'
    $col14 = $data.'Patch Number'
	$col15 = $data.'SP'
	$col16 = $data.'Status2'

    $TableDataIN =  " INSERT INTO $table ([DC/LDR],[location],[ActiveNode/ServerName],[ClusterPair],[InstanceName],[DB_Name],[Status],
                     [TotalSizeMB],[TotalSizeGB],[Last_SQL_Restart],[DateCheck],[Version], [Patch Number],[SP],[Status2])
                     VALUES ('$col1','$col2','$col3','$col4','$col5','$col6','$col7','$col8','$col9','$col10',
                     '$col12','$col13','$col14','$col15','$col16');"

    Invoke-Sqlcmd -ServerInstance $hostInstance -database $databasename -Query $TableDataIN
    
    }

 return "SUCCESS >> 2000 VERSION DATA" 
################## OUTPUT ################################    

#$Report | select-object 'DC/LDR',location,'ActiveNode/ServerName',ClusterPair,InstanceName,DB_Name,Status,TotalSizeMB,TotalSizeGB,Last_SQL_Restart,'User_Access_Activities(After Last SQL Restart)',DateCheck,Version,'Patch Number',SP,Status2 |`
#ConvertTo-Csv -NoTypeInformation | Select-Object -Skip 1| Out-File  -Append $filename1 
}
catch
{
        $err = $_.Exception.Message
		ErrorLog("Error: Unable to insert into SQL : $err")
		return "ERROR ## 2000 VERSION DATA"
}

}

function fnSQLtabledata2000Accessdata($tabledata1)
{
#$hostInstance = "EUDVMMSSQL100\INS10"
#$databasename = "CapacityReport"
$table = '[dbo].[tlb_KCOFINT64_Accessdata]'

try
{
    foreach ($data in $tabledata1)
    {

    ## Data Inserting to DB table

    $col1  = $data.'InstanceName'
    $col2  = $data.'DB_Name'
	$col3 = $data.'User_Access_Activities(After Last SQL Restart)'

$TableDataIN =  " INSERT INTO $table ([InstanceName],[DB_Name],[User_Access_Activities(After Last SQL Restart)])
                     VALUES ('$col1','$col2','$col3');"


    Invoke-Sqlcmd -ServerInstance $hostInstance -database $databasename -Query $TableDataIN
    
    }

 return "SUCCESS ## 2000 VERSION ACCESS DATE" 
################## OUTPUT ################################    

#$Report | select-object 'DC/LDR',location,'ActiveNode/ServerName',ClusterPair,InstanceName,DB_Name,Status,TotalSizeMB,TotalSizeGB,Last_SQL_Restart,'User_Access_Activities(After Last SQL Restart)',DateCheck,Version,'Patch Number',SP,Status2 |`
#ConvertTo-Csv -NoTypeInformation | Select-Object -Skip 1| Out-File  -Append $filename1 
}
catch
{
        $err = $_.Exception.Message
		ErrorLog("Error: Unable to insert into SQL : $err")		
		return "ERROR >>> 2000 VERSION ACCESS DATE"
}

}


################## Main Loop ################################  

foreach($Instance in $ServerInstance)
{
    $Counting += 1
    Write-Progress -Activity "$Counting. WORK with input data" -status "Working on row $Counting" -percentComplete (($Counting) / $InputLines * 100)

    ### Snapings sql modules
    #######################################
    asnp SqlServer* -ea 0
    " @@ working with $Instance " |Out-File -FilePath $errorlog -Append 

    try
    {  
    if($Instance -ne $null -and $Instance -ne 0)
    {
    
            ### CSV output
            if($Instance -ne "KCOFINT64")
            {
                ## Non SQL 2000 versions
                $tabledata = Invoke-Sqlcmd -ServerInstance $Instance -InputFile $inputFile
                $status = fnSQLtabledatamain($tabledata)
                $status = $Instance + " >>> " + $Status
                ErrorLog($Status)        
            }
            else
            {
                if(Test-Connection -ComputerName $Instance -Count 1 -Quiet)
                {                 
                ## SQL 2000 version data collection
                $tabledata2k = Invoke-Sqlcmd -ServerInstance $Instance -InputFile $inputfile2000 
                $status = fnSQLtabledata2000($tabledata2k)
                $status = $Instance + " >>> " + $Status
                ErrorLog($Status)

                ## SQL 2000 version last access date collection
                $tabledata1 = Invoke-Sqlcmd -ServerInstance $Instance -InputFile $inputfile2000Access 
                $status1 = fnSQLtabledata2000Accessdata($tabledata1)
                $status1 = $Instance + " >>> " + $Status1
                ErrorLog($Status1)

                ## 
                $tabledata2 = Invoke-Sqlcmd -ServerInstance $hostInstance -InputFile $finalcollection
                $status2 = fnSQLtabledatamain($tabledata2)
                $status2 = $Instance + " >>> " + $Status2
                ErrorLog($Status2) 
                }
                else { ErrorLog("$Instance server not pinging") }     
            }
            
    }
    else
    { ErrorLog("### Connection error on ### $Instance ")}

   } ## try close
    catch{ ErrorLog("Catch block ## Something wrong with ### $Instance ") }
  } ## For loop close

################## OUTPUT START ################################

<#
$pathDir = "D:\DATA\SQL_Support\DBA\Script\CapacityReport\DC\"
$filedate = (Get-Date).tostring(“yyyyMMdd_HHmmss”)
$export_csv = $pathDir + 'MonthlyCapacityReportCSV_' + $filedate + '.csv'
$finalScript = "D:\DATA\SQL_Support\DBA\Script\CapacityReport\DC\CapacityFinalScriptDC.sql"
#>

"### Final report preparation" |Out-File -FilePath $errorlog -Append
Invoke-Sqlcmd -ServerInstance $hostInstance -InputFile $finalScript |`
select-object 'DC/LDR',location,'ActiveNode/ServerName',ClusterPair,InstanceName,DB_Name,Status,`
TotalSizeMB,TotalSizeGB,Last_SQL_Restart,'User_Access_Activities(After Last SQL Restart)',`
DateCheck,Version,'Patch Number',SP,Status2 |`
export-csv -path $export_csv -Delimiter "," -NoClobber -NoTypeInformation -append

"### CSV to DB START ##" |Out-File -FilePath $errorlog -Append
D:\DATA\SQL_Support\DBA\Script\CapacityReport\DC\ps_csv_dbtable.ps1 -path $export_csv


#$emailstatus = fnemailcopy($export_csv)
#$emailstatus | Out-File -FilePath $errorlog -Append

$htmllist = "<!DOCTYPE html>"
$htmllist += "<html><head><style>div{ background-color: lightgrey; font-family:Tahoma; font-size:8pt; width: 100px;  border: 2px solid black;  padding: 5px;  margin: 1px;}</style></head>"
$htmllist += "<body><h2>Monthly Capacity Report</h2>"
$htmllist += "<div>Report Date : $End <br>Varsion : 1.0 <br>DurationInSec: $Duration <br>Number of Servers : $Counting </div>" 
$htmllist += "</body></html>"

## Email setting
$fromaddress = "tsy_abazar@konenet.com" 
#$toaddress = "FMB-TS-Delivery-SL-CSS-DB-OPS-SQL@t-systems.com"
$toaddress = "Ashok-Sagar.Bazar@t-systems.com"
$Subject = "<<<Automated Report >>> Monthly Capacity Report"  
$smtpserver = "eudsmtp.konenet.com" 
$message = new-object System.Net.Mail.MailMessage
$message.From = $fromaddress
$message.To.Add($toaddress)
$message.IsBodyHtml = $True
$message.Subject = $Subject
If (-Not $export_csv.Length -eq 0){ $message.Attachments.Add($export_csv)}
#$message.body = "Capacity Report Monthly"
$message.Body = $message.Body + $htmllist
$smtp = new-object Net.Mail.SmtpClient($smtpserver)
$smtp.Send($message)


$End = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$duration = (NEW-TIMESPAN –Start $start –End $End).Seconds 
"### Duration of the script ### "  + $duration  | Out-File -FilePath $errorlog -Append
"### Number of Servers ### " + $Counting | Out-File -FilePath $errorlog -Append
"### END TIME "+ $(Get-Date -Format "yyyy-MM-dd HH:mm:ss") + " ###" | Out-File -FilePath $errorlog -Append



################################################################################################
# FileName ps_csv_dbtable.ps1
################################################################################################
$hostInstance = "EUDVMMSSQL100\INS10"
$subcounting = 0
$databasename = "CapacityReport"
$tableQuery = "D:\DATA\SQL_Support\DBA\Script\CapacityReport\DC\tlb_everymonthReport.sql"
$tablename = Invoke-Sqlcmd -ServerInstance $hostInstance -database $databasename -InputFile $tableQuery
$table = '[dbo].' + '[' + $tablename.TABLE_NAME + ']'
$dbtable = Import-Csv -Path $export_csv
$InputLines = ($dbtable).Count

foreach($data in $dbtable)
{
    $subcounting += 1
    Write-Progress -Activity "$subcounting. WORK with input data" -status "Working on row $subcounting" -percentComplete (($subcounting) / $InputLines * 100)
             
    try{
    $col1  = $data.'DC/LDR'
    $col2  = $data.'location'
    $col3  = $data.'ActiveNode/ServerName'
    $col4  = $data.'ClusterPair'
	$col5  = $data.'InstanceName'
	$col6  = $data.'DB_Name'
	$col7  = $data.'Status'
	$col8  = $data.'TotalSizeMB'
    $col9  = $data.'TotalSizeGB'
	$col10 = $data.'Last_SQL_Restart' 
	$col11 = $data.'User_Access_Activities(After Last SQL Restart)'
    $col12 = $data.'DateCheck'
	$col13 = $data.'Version'
    $col14 = $data.'Patch Number'
	$col15 = $data.'SP'
	$col16 = $data.'Status2'

    $TableDataIN =  " INSERT INTO $table ([DC/LDR],[location],[ActiveNode/ServerName],[ClusterPair],[InstanceName],[DB_Name],[Status],
                     [TotalSizeMB],[TotalSizeGB],[Last_SQL_Restart],[User_Access_Activities(After Last SQL Restart)],[DateCheck],[Version],
                     [Patch Number],[SP],[Status2])
                     VALUES ('$col1','$col2','$col3','$col4','$col5','$col6','$col7','$col8','$col9','$col10',
                     '$col11','$col12','$col13','$col14','$col15','$col16');"

    Invoke-Sqlcmd -ServerInstance $hostInstance -database $databasename -Query $TableDataIN
    }
        catch{$err = $_.Exception.Message}    

}




