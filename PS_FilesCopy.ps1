## Version 1.0
## Script : Copy CSV files from different source servers
## Last write time either 10 or choose 
## Script Writer : Ashok Sagar
#############################################################################################


param ( $Counting = 0,
        $FilesCounting = 0,
        $pingnot = 0,
        $Retention = 10)
        
        $Startime = get-date
        $start = get-date -Format yyyyMMdd_HHmmss
        $Servers = Get-Content C:\temp\FileShare\CopyFiles\masterServers.txt
        $Logfile = "C:\temp\FileShare\CopyFiles\LogFile_" + $start + ".log"


"START" + ">>>" + $Startime | out-file -append $LogFile
" " | out-file -append $LogFile 
## Create folder before running script and with number of days old data to collect
########################################################################################
$DestinationPath = "C:\temp\AzwanFSReport\CopyTest\"
########################################################################################

$inputvalue = $Servers.Count
#$inputvalue
foreach ($server in $Servers)
{
$Counting += 1

Write-Progress -Activity "$Counting... $server.... in progress...." -status "Working on row $Counting" -percentComplete (($Counting) / $inputvalue * 100)

$ping = Test-Connection -ComputerName $server -Count 1 -Quiet -ErrorAction SilentlyContinue

if($ping)
{
"     Ping" + $server + " >> [ OK ] " | out-file -append $LogFile 
$SourcePath = "\\" + $server + "\c$\temp\FileShare\Report\*.csv"
$CopyFiles = Get-ChildItem -path $SourcePath -Include *.csv | Where-Object { $_.LastWriteTime -gt (get-date).AddDays(-$Retention)}
$CopyFiles | out-file -append $LogFile 

    foreach($file in $CopyFiles.fullname)
    {
    try
    {
    $FilesCounting += 1
    write-host "Copy in progress...." $file
    "     Copy in progress" + $file | out-file -append $LogFile
    Copy-Item -Path $file -Destination $DestinationPath
    }
    catch
    {
    $Error = $_.Exception.Message
    $file + "  " + $Error |out-file -append $LogFile   
    }
    }

}
else
{
    $pingnot += 1
    "     Ping " + $server + " >> [ NOT OK ] " | out-file -append $LogFile 
}
"     Server" + $server + "Number of Files" + $FilesCounting | out-file -append $LogFile
" " | out-file -append $LogFile
$FilesCounting = 0
}
$end = get-date
"END" + ">>>" + $end | out-file -append $LogFile
" " | out-file -append $LogFile
"REPORT SUMMARY" + ">>>" | out-file -append $LogFile
" " | out-file -append $LogFile
"Servers: " + $Counting | out-file -append $LogFile
"Connection Failed: " + $pingnot  | out-file -append $LogFile
"Files: " + $FilesCounting  | out-file -append $LogFile
"Duration_Seconds :" + (NEW-TIMESPAN –Start $Startime –End $end).Seconds | out-file -append $LogFile




