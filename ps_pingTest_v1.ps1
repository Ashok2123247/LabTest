### Variable declaration
Clear-host
$DBping = 0
$DBnoPing = 0
$Count = 0
$ServerPing =0
$ServerNoPing = 0
$start = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$filedate = (Get-Date).tostring(“yyyyMMdd_HHmmss”)

## Path declaration
$pathDir = "D:\DATA\SQL_Support\DBA\DBA_Automation\EUDVMMSSQL100_AutoJobs\PingTest\"
$inputfile = $pathDir + "Instances.txt"
$OldInstanceName = " "

## Remove existing files
Remove-Item -Path $pathDir* -Include PingLogReport*.log -ErrorAction Continue 

$logReport = $pathDir + 'PingLogReport_' + $filedate + '.log'

#$DataSourceList = "EUDVMMSSQL100\INS10","EUDVMMSSQL100\INS10"

$DataSourceList = Get-Content $inputfile

"START TIME "+ $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")| Out-File -FilePath $logReport -Append
" " |Out-File -FilePath $logReport -Append

ForEach ($ds in $DataSourceList) {
        $Count += 1
        $dsNew = $ds
        $Server = $ds.Split("\")
	    $ServerName = $Server[0]
asnp SqlServer* -ea 0
Write-Progress -Activity "$Count ...Pingtest on $dsNew "-percentComplete (($Count) / ($DataSourceList.count) * 100)

if($OldInstanceName -ne $ServerName -and $ServerName -ne $null){

        $test = Test-Connection -ComputerName $ServerName -Quiet -Count 1 
        if($test)
        { 
            Write-Host "SERVER PING [OK]"  $ServerName -ForegroundColor green 
            "SERVER PING [OK]" + $ServerName | Out-File -FilePath $logReport -Append            
            $ServerPing += 1
         } 
         else {
            $ServerNoPing +=1 
            Write-Host "SERVER PING [NOT OK]" $ServerName -ForegroundColor DarkRed
            "SERVER PING [NOT OK]" + $ServerName | Out-File -FilePath $logReport -Append}
            $OldInstanceName = $ServerName
         } 

          ## Instance Check

            try{
                $result = Invoke-Sqlcmd -ServerInstance $dsNew -database "master" "select @@SERVICENAME" 
 
            if ($result) {
                    $DBping += 1 
                    Write-Host "DB PING [OK]" $dsNew -ForegroundColor darkGreen
                    "DB PING [OK]" + $dsNew | Out-File -FilePath $logReport -Append}    
            }catch{
                    $DBnoPing += 1 
                    write-host "DB PING [NOT OK]" $dsNew -ForegroundColor Red
                    "DB PING [NOT OK]" + $dsNew | Out-File -FilePath $logReport -Append}  
  
}     
 

" " |Out-File -FilePath $logReport -Append
"REPORT SUMMARY" |Out-File -FilePath $logReport -Append
" " |Out-File -FilePath $logReport -Append
" " |Out-File -FilePath $logReport -Append

"TOTAL SERVERS COUNT " + $Count |Out-File -FilePath $logReport -Append
"PING [OK] SERVERS " + $ServerPing |Out-File -FilePath $logReport -Append
"PING [NOT OK] SERVERS " + $ServerNoPing |Out-File -FilePath $logReport -Append
"PING [OK] DB " + $DBping |Out-File -FilePath $logReport -Append
"PING [NOT OK] DB " + $DBnoPing |Out-File -FilePath $logReport -Append

write-host "TOTAL SERVERS COUNT "  $Count 
write-host "PING [OK] SERVERS "  $ServerPing 
write-host "PING [NOT OK] SERVERS "  $ServerNoPing 
write-host "PING [OK] DB "  $DBping 
write-host "PING [NOT OK] DB "  $DBnoPing 