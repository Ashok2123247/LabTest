<#
    Stopping SQL Services on Windows server (Single or Multiple)
    Version : 1.0
    Author : Ashok Sagar Bazar
    Environment : Windows 2008R2
    Browser compatability: Chrome, Fireforx
    Powershell Version : 3.0
    Dfefault output path : C:\Temp

#>

### Variable declaration
Clear-host
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned
$Count = 0 #Servercount
$ServerPing =0  
$ServerNoPing = 0  
$start = Get-Date
$filedate = Get-Date -Format "yyyyMMdd-HHmmss"
$pathDir = "C:\Temp\"
#Remove-Item –path $pathDir* -include LogReport*.log -ErrorAction Ignore
#Remove-Item –path $pathDir* -include DBReport*.html -ErrorAction Ignore
$logReport = $pathDir + 'LogReport_' + $filedate + '.log'
$filename = $pathDir + 'DBReport_' + $filedate + '.html'

$a = @'
<style>body{background-color:#566573;}
.container{	width:73%; margin:auto; margin-top: 15px;background-color:#F8F9F9;overflow:hidden; box-shadow: 10px 10px }
.headerbox {width:auto%; padding-left:10px;padding-right:10px;padding-top:5px;padding-bottom:0px; }
.p.a{font:0.4em/145% Segoe UI;font-style: oblique;}
.TABLE1{width:auto%;font:0.7em/145% Segoe UI,helvetica,Segoe UI,Segoe UI;}
.headerbox.h1{font-family:Castellar;padding-bottom:0px}
.datacon{color:#17202A;width:auto%;background-color :#B2BABB;padding:20px;}
.databox {color:#17202A;width:auto%;background-color :#B2BABB;}
.databox.h3{color:#17202A;font-family :Castellar;line-height: normal; }
TABLE{width:100%;border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;font:0.6em/145% Segoe UI,helvetica,Segoe UI,Segoe UI;}
TH{border-width: 1px;padding: 3px;border-style: solid;border-color: black;background-color:#778899}
TD{border-width: 1px;padding: 3px;border-style: solid;border-color: black;}
tr:nth-child(odd) { background-color:#F2F2F2;}
tr:nth-child(even) { background-color:#DDDDDD;}
.footer{width:auto%; padding:10px;text-align:right;font:0.6em/145% Segoe UI;line-height: normal;font-style: oblique;line-height: 1;}
</style>
'@
$ColorFilter = @{
                    Running = ' style="color:Green">Running<';
                    Stopped = ' style="color:RED">Stopped<';
                    ONLINE = ' style="color:Green">ONLINE<';
                    OFFLINE = ' style="color:RED">OFFLINE<';
                    NOTHEALTHY = ' style="color:RED">NOTHEALTHY<';
                    HEALTHY = ' style="color:Green">HEALTHY<';
                    RESTORING = ' style="color:magenta">RESTORING<';                  
                }
$a =  $a + '<div class="container"> <div class ="headerbox"><h1>DB STOP/START ACTIVITY</h1><div class = "table1">Date: ' + $start + ' || Version : 1.0  || </div></div>'| Out-File -append $filename
$a =  $a + '<div class = "datacon">' | Out-File -append $filename


################  INPUT FILE ###########################
#$Inputfile = Get-Content C:\temp\Servers.txt
########################################################
Write-Host "Enter SQL Servers by using comma separator or Text file path with all SQL Server list" -ForegroundColor yellow
Write-host "Output file should be under c:\Temp\ folder" -ForegroundColor Yellow
$Inputfile = Read-host "Enter SQL Server list"
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

            [string[]]$instances = get-service -computerName $ServerName  |` 
            where-object {$_.Name -like "MSSQL$*" -or $_.Name -like "SQLAgent$*" -or $_.name -like "SQLBrowser" `
            -or $_.DisplayName -like "*Full-text*" -or $_.name -like "MSSQLSERVER" -or $_.name -like "SQLSERVERAGENT" } |`
            Select-Object Name,DisplayName,Status | Sort-Object Name| ConvertTo-HTML -head $a -body "<h5>BEFORE ACTIVITY ON $ServerName </h5>" | out-string
            $ColorFilter.Keys | foreach { $instances = $instances -replace ">$_<",($ColorFilter.$_) }
            $instances | Out-File -append $filename
            
                        
            if($InputStatus -eq 'STOP'){
            write-host ""
            Write-Host "STOPPING SERVICES IN PROGRESS..." -ForegroundColor Yellow
            ####################     STOP      ####################
            get-service -computerName $ServerName  |` 
            where-object {$_.Name -like "MSSQL$*" -or $_.Name -like "SQLAgent$*" -or $_.name -like "SQLBrowser" `
            -or $_.DisplayName -like "*Full-text*" -or $_.name -like "MSSQLSERVER" -or $_.name -like "SQLSERVERAGENT" } | `
            Where-Object {$_.status -eq "Running"} | Stop-Service -confirm -force
            ########################################################
            }else { 
            write-host " "
            Write-Host "STARTING SERVICES IN PROGRESS..." -ForegroundColor Yellow
            ####################     START      ####################

            get-service -computerName $ServerName  |` 
            where-object {$_.Name -like "MSSQL$*" -or $_.Name -like "SQLAgent$*" -or $_.name -like "SQLBrowser" `
            -or $_.DisplayName -like "*Full-text*" -or $_.name -like "MSSQLSERVER" -or $_.name -like "SQLSERVERAGENT" } | `
            Where-Object {$_.status -eq "Stopped"} | start-service

            try{
            $Instance = Invoke-Command -ComputerName $ServerName {(Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server').InstalledInstances} 
            $Instance = $Instance.replace("MSSQLSERVER",$null)  
            foreach($server in $Instance)
            {
                asnp SqlServer* -ea 0 ## Snapin SQL
                
                    if($server.Length -ne 0 )
                    {
                        $servername2 = $ServerName + "\" + $server 
                        $servername2                                      
                        ## Database Information
                        [string[]]$html = Invoke-Sqlcmd -ServerInstance $servername2 -Query $SQLQuery |`
                        Select-Object ServerName,DBName,DB_Status| ConvertTo-HTML -head $a -body "<h5>Database Status $servername2 </h5>" |out-string
                        $ColorFilter.Keys | foreach { $html = $html -replace ">$_<",($ColorFilter.$_) }
                        $html | Out-File -append $filename }                    
                    else{
                        $servername2 = $ServerName
                        $servername2                        
                        ## Database Information
                        [string[]]$html = Invoke-Sqlcmd -ServerInstance $servername2 -Query $SQLQuery |`
                        Select-Object ServerName,DBName,DB_Status| ConvertTo-HTML -head $a -body "<h5>Database Status $servername2 </h5>" |out-string
                        $ColorFilter.Keys | foreach { $html = $html -replace ">$_<",($ColorFilter.$_) }
                        $html | Out-File -append $filename }
                        
              } #for
              } #try                  
             catch{write-host "DB PING [NOT OK]" -ForegroundColor Magenta }
             }  # else 
                         
            [string[]]$instanceafter = get-service -computerName $ServerName  |` 
            where-object {$_.Name -like "MSSQL$*" -or $_.Name -like "SQLAgent$*" -or $_.name -like "SQLBrowser" `
            -or $_.DisplayName -like "*Full-text*" -or $_.name -like "MSSQLSERVER" -or $_.name -like "SQLSERVERAGENT" } |`
            Select-Object Name,DisplayName,Status | Sort-Object Name| ConvertTo-HTML -head $a -body "<h5>AFTER ACTIVITY ON  $ServerName </h5>" | out-string
            $ColorFilter.Keys | foreach { $instanceafter = $instanceafter -replace ">$_<",($ColorFilter.$_) }
            $instanceafter | Out-File -append $filename
            
            [string[]]$instances1 = get-service -computerName $ServerName  |` 
            where-object {$_.Name -like "MSSQL$*" -or $_.Name -like "SQLAgent$*" -or $_.name -like "SQLBrowser" `
            -or $_.DisplayName -like "*Full-text*" -or $_.name -like "MSSQLSERVER" -or $_.name -like "SQLSERVERAGENT" }|Out-String
            $instances1


         }# main if  
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
remove-variable instances1
