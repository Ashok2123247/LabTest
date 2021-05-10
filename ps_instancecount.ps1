## Find the Instances on each server
Clear-Host
$ErrorActionPreference = "Stop"
Remove-Item -Path C:\temp\DBA\* -Include InstanceReport_*.log -ErrorAction SilentlyContinue

$start = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$Counting = 0
$Date = Get-Date -Format ddMMyyy-hhmmss
$Path = "C:\temp\DBA\"
$logFile = $Path + "InstanceReport_" + $Date + ".log"

$server = "EUDVMMSSQL100","EUDVMMSSQL101","EUDVMMSSQL102","EUDVMMSSQL103","EUDVMMSSQL201","EUDVMMSSQL202","EUDVMMSSQL203","EUDVMMSSQL204","EUDVMMSSQL205","EUDVMMSSQL206"
foreach($server1 in $server)
{
    try{
    $Instance = Invoke-Command -ComputerName $server1 {(Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server').InstalledInstances} -ErrorAction SilentlyContinue
    $Instance = $Instance.replace("MSSQLSERVER",$null)  
    foreach($servername in $Instance)
    {
        if($servername.Length -ne 0 ){
         $servername2 = $server1 + "\" + $servername 
         $servername2 |out-file -Append $logFile 
         
                 
         }
        else{
            $servername2 = $server1
            $servername2}    
      }
    }
    catch{
    Write-Host "PING [NOT OK] >> $server1"   -ForegroundColor yellow
    }
}


==================================================================================================

$Instance = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server').InstalledInstances 
foreach($servername in $Instance)
{
    if($servername.Length -ne 0 ){
        $servername2 = $env:computername + "\" + $servername 
        $servername2 }  
    
}

==================================================================================================

## Find the Instances on each server

$server = "EUDVMMSSQL103","EUDVMMSSQL206"
foreach($server1 in $server)
{
    $Instance = Invoke-Command -ComputerName $server1 {(Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server').InstalledInstances}
    $Instance = $Instance.replace("MSSQLSERVER",$null)  
    foreach($servername in $Instance)
    {

    if($servername.Length -ne 0 ){
        $servername2 = $server1 + "\" + $servername 
        $servername2 }
   else{
    $servername2 = $server1
    $servername2}    
    }
}
