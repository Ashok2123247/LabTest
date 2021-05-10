
### Variable declaration
clear-host
asnp SqlServer* -ea 0
$Counting = 0 
$start = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$filedate = (Get-Date).tostring(“yyyyMMdd_HHmmss”)
## Path declaration
$pathDir = "D:\DATA\SQL_Support\DBA\DBA_Automation\App_ID_ConnCount\"
$errorlog = $pathDir + 'LogFile_' + $filedate + '.log'
## Remove existing files
Remove-Item -Path $pathDir* -Include LogFile*.log -ErrorAction Continue |where {$_.lastwritetime -lt (get-date).adddays(-30)} 
### SQL Script files
$delete_rows = $pathDir + "tsql_deleteRows.sql"
$inputFile = $pathDir +  "tsql_ClientAddressConnCount.sql"
$finalScript = $pathDir + "FinalOutput.sql"
"START TIME "+ $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")| Out-File -FilePath $errorlog -Append
## Delete the table rows
Invoke-Sqlcmd -ServerInstance $hostInstance -InputFile $delete_rows
$ServerInstance = get-content ($pathDir + 'Instances.txt')
#$ServerInstance = "EUDVMMSSQL100\INS10","KCOFIVMNT001"
$linecount = $ServerInstance.count
Function ErrorLog ($Logstring)
{
$msg = $filedate + " " + $Logstring
Out-File -FilePath $errorlog -InputObject $msg -append
}
################## Main Loop ################################  
foreach($Instance in $ServerInstance)
{
    $Counting += 1    
    Write-Progress -Activity "$Counting .. Working on row $Instance"  -percentComplete ($Counting / $linecount * 100)

    try
    {    
                ## Non SQL 2000 versions
               $tabledata = Invoke-Sqlcmd -ServerInstance $Instance -InputFile $inputFile 
               ErrorLog("### Ping OK        >> $Instance")
                foreach ($data in $tabledata)
                {
                $table = "[dbo].[ConnectionCount]"

                $col1  = $data.'ActiveNode/ServerName'
	            $col2  = $data.'InstanceName'
	            $col3  = $data.'DB_Name'
	            $col4 = $data.'loginame'
                $col5 = $data.'login_time'
                $col6 = $data.'session_id'
                $col7 = $data.'net_transport'
                $col8 = $data.'host_name'
	            $col9 = $data.'program_name'
                $col10 = $data.'client_interface_name'
                $col11 = $data.'client_net_address'
                $col12 = $data.'local_net_address'
                $col13 = $data.'connect_time'
                $col14 = $data.'Last_SQL_Restart'
                $col15 = $data.'ConnCount'
                $col16 = $data.'Last_Read_AfterRestart'
                $col17 = $data.'Last_Write_AfterRestart'
                $col18 = $data.'Status2'

                $TableDataIN =  " INSERT INTO $table ([ActiveNode/ServerName]
                                ,[InstanceName]
                                ,[DB_Name]
                                ,[loginame]
                                ,[login_time]
                                ,[session_id]
                                ,[net_transport]
                                ,[host_name]
                                ,[program_name]
                                ,[client_interface_name]
                                ,[client_net_address]
                                ,[local_net_address]
                                ,[connect_time]
                                ,[Last_SQL_Restart]
                                ,[ConnCount]
                                ,[Last_Read_AfterRestart]
                                ,[Last_Write_AfterRestart]
                                ,[Status2])
                VALUES ('$col1','$col2','$col3','$col4','$col5','$col6','$col7','$col8',`
                '$col9','$col10','$col11','$col12','$col13','$col14','$col15','$col16','$col17','$col18');"                   

                 Invoke-Sqlcmd -ServerInstance "EUDVMMSSQL100\INS10" -database "ClientAddress" -Query $TableDataIN 
                }                

   } catch{ ErrorLog("### Ping NOT OK    >> $Instance")}

} 

"END TIME "+ $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")| Out-File -FilePath $errorlog -Append


