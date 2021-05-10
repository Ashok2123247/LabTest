
Clear-host
#Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force
$InstanceName = @()
Write-Host "Enter Instance names by using comma separator or input text file with multiple Instance details." -ForegroundColor Green
Write-host "Output file should be under c:\Temp\ folder" -ForegroundColor Yellow
$InstanceName = Read-host "Enter Instance list or input txt file path"
If($InstanceName -like "*.txt"){
$InstanceName = Get-Content $InstanceName}
else{$InstanceName = $InstanceName.Split(',').Split(' ')}
#$InstanceName
$ErrorActionPreference = "Stop"
$start = (get-date -DisplayHint DateTime).DateTime
$Counting = 0
$pathDir = "C:\temp\"
$filedate = (Get-Date).tostring(“ddMMyyyy-hhmmss”)
$filename= $pathDir + 'HealthCheck_Report_' + $filedate + '.html'
$OldInstanceName = " "
Remove-Item –path $pathDir* -include HealthCheck_Report*.html -ErrorAction Ignore
###################################################
## HTML Script Block
###################################################
$a = @'
<style>body{background-color:#566573;}
.container{	width:90%; margin:auto; margin-top: 15px;background-color:#F8F9F9;overflow:hidden; box-shadow: 10px 10px }
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
$a =  $a + '<div class="container"> <div class ="headerbox"><h1>Health Check Report</h1><div class = "table1">Date: ' + $start + ' || Version : 2.0  || </div> 
<div class = "table1"><p style="color:red">Critical < 10% [Disk space is less than 10%]</p><p style="color:Magenta;">Warning < 20% [Disk space is less than 20%]</p><p style="color:green;">Heatlthy < 30 % [Disk space is less than 10%]</p></div></div>'| Out-File -append $filename
$a =  $a + '<div class = "datacon">' | Out-File -append $filename
## SQL Query Block  
################################################### 
$SQLQuery = "select @@Servername as ServerName,name as DBName,database_id,compatibility_level,
page_verify_option_desc,log_reuse_wait_desc,state_desc as DB_Status
from sys.databases"
## Looping start
###################################################
foreach($InsNames in $InstanceName)
{
asnp SqlServer* -ea 0 ## Snapin SQL
$Counting = $Counting + 1
$InsNames1 = $InsNames
Write-Progress -Activity "$Counting..$InsNames ... in progress.." -percentComplete (($Counting) / ($InstanceName.Count) * 100)
    ## Try block Begin
    try
    {
            ## Split ServerName and InstanceNames
            $Instance = $InsNames.Split("\")
            $ServerName = $Instance[0]
                 
            if ($OldInstanceName -ne $ServerName)
            { ## IF Begin            
            ## SQL Services information
            [string[]]$html3 = get-service -computerName $ServerName  |` 
            where-object {$_.Name -like "MSSQL$*" -or $_.Name -like "SQLAgent$*" -or $_.name -like "SQLBrowser" -or $_.DisplayName -like "*Full-text*" -or $_.name -like "MSSQLSERVER" -or $_.name -like "SQLSERVERAGENT" } |`
            Select-Object Name,DisplayName,Status | Sort-Object Name| ConvertTo-HTML -head $a -body "<h5>SQL Services $ServerName </h5>" | out-string
            $ColorFilter.Keys | foreach { $html3 = $html3 -replace ">$_<",($ColorFilter.$_) }
            $html3 | Out-File -append $filename
            ## Disk Information
            [string[]]$htmlDisk = Get-WmiObject -computername $ServerName -query "select SystemName, DriveType, FileSystem, FreeSpace, Capacity, Label
		    from Win32_Volume where DriveType = 2 or DriveType = 3" | ForEach { New-Object PSObject -Property @{
            SystemName = $_.systemName
            LABEL = $_.Label
            SIZEInGB = ([Math]::Round($_.Capacity/1GB,2))
            UsedSizeInGB = ([Math]::Round($_.Capacity/1GB - $_.FreeSpace/1GB,2))
            FREESizeInGB = ([Math]::Round($_.FreeSpace/1GB,2))
            UsedPercentage =  ([Math]::Round(($_.Capacity/1GB - $_.FreeSpace/1GB)/($_.Capacity/1GB) * 100,2))
            FreePercentage = ([Math]::Round(($_.freespace/1GB)/ ($_.Capacity/1GB) * 100,2))
            DiskStatus = if(([Math]::Round(($_.freespace/1GB)/ ($_.Capacity/1GB) * 100)) -lt 20){'NOTHEALTHY' }else {'HEALTHY'}
            }}|Select-Object SystemName,LABEL,SIZEInGB,UsedSizeInGB,FREESizeInGB,UsedPercentage,FreePercentage,DiskStatus |`
            ConvertTo-HTML -head $a -body "<H5>Disk Management $ServerName </H5>" |out-string
            $ColorFilter.Keys | foreach { $htmlDisk = $htmlDisk -replace ">$_<",($ColorFilter.$_) }
            $htmlDisk | Out-File -append $filename
            $OldInstanceName = $ServerName
            } ## If ends

            ## Database Information
            [string[]]$html = Invoke-Sqlcmd -ServerInstance $InsNames1 -Query $SQLQuery |`
            Select-Object ServerName,DBName,database_id,compatibility_level,page_verify_option_desc,log_reuse_wait_desc,DB_Status|`
            ConvertTo-HTML -head $a -body "<h5>Database Status $InsNames1 </h5>" |out-string
            $ColorFilter.Keys | foreach { $html = $html -replace ">$_<",($ColorFilter.$_) }
            $html | Out-File -append $filename
            }## Try block End

            ## Catch block Begin
            catch 
                { write-host "PING [NOT OK]" $InsNames1 -ForegroundColor Magenta }
} ## Looping End
### counting Number of Instances
$End = get-date
write-host "EndTime: "  $End
Write-host "Duration_Seconds :" (NEW-TIMESPAN –Start $start –End $End).Seconds
Write-host "Number of Instances :" $Counting
remove-variable Counting
remove-variable OldInstanceName
remove-variable start
remove-variable filename
remove-variable InstanceName
remove-variable pathDir
remove-variable SqlQuery







