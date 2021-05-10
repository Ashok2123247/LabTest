### Variable declaration
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned
Clear-host
$Count = 0
$ServerPing =0
$ServerNoPing = 0
$start = Get-Date -Format "yyyyMMdd-HHmmss"
$filedate = (Get-Date).tostring(“ddMMyyyy-hhmmss”)
$pathDir = "C:\Temp\"
$logReport = $pathDir + 'LogReport_' + $filedate + '.log'

################  INPUT FILE ###########################
#$Inputfile = Get-Content C:\temp\Servers.txt
########################################################
#Remove-Item –path $pathDir* -include LogReport*.log -ErrorAction Ignore
$Inputfile = Read-host "Enter Server list only by using text file (Don't enter instance names)"
If($Inputfile -like "*.txt"){
$Inputfile = Get-Content $Inputfile}
else{$Inputfile = $Inputfile.Split(',').Split(' ')}
$linecount = $inputfile.count
$InputStatus = Read-host "Enter STOP/START " 
$InputStatus=$InputStatus.ToUpper()
Clear-Host
$SQLQuery = "select @@Servername as ServerName,name as DBName,state_desc as DB_Status from sys.databases"
"START TIME "+ $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")| Out-File -FilePath $logReport -Append
" " |Out-File -FilePath $logReport -Append
foreach ($ServerName in $inputfile)
{
$count += 1
asnp SqlServer* -ea 0
Write-Progress -Activity "$Count ...Pingtest on $ServerName "-percentComplete ($Count / $linecount * 100)

        $test = Test-Connection -ComputerName $ServerName -Quiet -Count 1 
        if($test)
        { 
            Write-Host "SERVER PING [OK]"  $ServerName -ForegroundColor green 
            "SERVER PING [OK]" + $ServerName | Out-File -FilePath $logReport -Append            
            $ServerPing += 1


            $instances = get-service -computerName $ServerName  |` 
            where-object {$_.Name -like "MSSQL$*" -or $_.Name -like "SQLAgent$*" -or $_.name -like "SQLBrowser" `
            -or $_.DisplayName -like "*Full-text*" -or $_.name -like "MSSQLSERVER" -or $_.name -like "SQLSERVERAGENT" } 
            #|Select-Object Name,DisplayName,Status | Sort-Object Name |ft -AutoSize
            
            echo " "  >>$logReport
            echo " "
            Echo "BEFORE STOP" >>$logReport
            Write-Warning "BEFORE STOP"
            Echo $instances  >> $logReport
            Echo $instances

            if($InputStatus -eq 'STOP'){
            write-host ""
            Write-Host "STOPPING SERVICES IN PROGRESS..." -ForegroundColor Yellow
            ####################     STOP      ####################
            $instances | Where-Object {$_.status -eq "Running"} |Stop-Service -force
            ########################################################
            }else {
            write-host ""
            Write-Host "STARTING SERVICES IN PROGRESS..." -ForegroundColor Yellow
            ####################     START      ####################
            $instances | Where-Object {$_.status -eq "Stopped"} |start-service
            try{
            $Instance = Invoke-Command -ComputerName $ServerName {(Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server').InstalledInstances} -ErrorAction SilentlyContinue
            $Instance = $Instance.replace("MSSQLSERVER",$null)  
            foreach($server in $Instance)
            {
            $servername2 = " "
            if($server.Length -ne 0 ){
             $servername2 = $ServerName + "\" + $server
             #$servername2 

             ## Database Information
                $dbreport = Invoke-Sqlcmd -ServerInstance $servername2 -Query $SQLQuery |`
                Select-Object ServerName,DBName,DB_Status|Out-String 
                Echo $dbreport >> $logReport
                Echo $dbreport
                }
                else{
                ## Default Instance 

                $servername2 = $ServerName
                #$servername2

                ## Database Information
                Invoke-Sqlcmd -ServerInstance $servername2 -Query $SQLQuery |`
                Select-Object ServerName,DBName,database_id,DB_Status |Out-String
                Echo $dbreport >> $logReport
                Echo $dbreport
                } 
              }                
 
              }catch{write-host "DB PING [NOT OK]" $servername2 -ForegroundColor Magenta } 
              
            }

            echo " " >> $logReport
            echo " "
            Echo "AFTER STOP" >> $logReport
            Write-Warning "AFTER STOP"
            echo " "  >> $logReport
            echo " "
            Echo $instances >> $logReport
            Echo $instances           
         } 
         else 
         {
            $ServerNoPing +=1 
            Write-Host "SERVER PING [NOT OK]" $ServerName -ForegroundColor Red
            "SERVER PING [NOT OK]" + $ServerName | Out-File -FilePath $logReport -Append             
         }
 }

 "END TIME "+ $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")| Out-File -FilePath $logReport -Append
 " " |Out-File -FilePath $logReport -Append

"REPORT SUMMARY" |Out-File -FilePath $logReport -Append
"TOTAL SERVERS COUNT " + $Count |Out-File -FilePath $logReport -Append
"PING [OK] SERVERS " + $ServerPing |Out-File -FilePath $logReport -Append
"PING [NOK] SERVERS " + $ServerNoPing |Out-File -FilePath $logReport -Append

write-host ""
Write-Host "REPORT SUMMARY" -ForegroundColor Yellow
write-host ""
write-host "TOTAL SERVERS COUNT "  $Count 
write-host "PING [OK] SERVERS "  $ServerPing 
write-host "PING [NOT OK] SERVERS "  $ServerNoPing


remove-variable instances
remove-variable count
remove-variable ServerNoPing
remove-variable ServerPing
remove-variable pathDir
remove-variable ServerName
remove-variable logReport

