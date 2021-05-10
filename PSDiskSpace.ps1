--https://techontip.wordpress.com/tag/get-disk-size-using-powershell/
#To get the all Disk space details from the PWRShell

Function Get-DisksSpace ($unit='GB')
{
$measure = "1$unit"

$ServerName=[System.Net.Dns]::GetHostName()

Get-WmiObject -computername $serverName -query "
select SystemName, DriveType, FileSystem, FreeSpace, Capacity, Label
  from Win32_Volume
 where DriveType = 2 or DriveType = 3" `
| select SystemName `
        , Name `
        , @{Label="SizeIn$unit";Expression={"{0:n2}" -f($_.Capacity/$measure)}} `
	, @{Label="UsedIn$unit";Expression={"{0:n2}" -f($_.Capacity/$measure - $_.freespace/$measure)}} `
        , @{Label="FreeIn$unit";Expression={"{0:n2}" -f($_.freespace/$measure)}} `
	, @{Label="UsedPercent";Expression={"{0:n2}" -f(($_.Capacity/$measure - $_.freespace/$measure)/($_.Capacity/$measure) * 100)}} `
        , @{Label="PercentFree";Expression={"{0:n2}" -f(($_.freespace / $_.Capacity) * 100)}} `
        ,  Label
}#Get-DisksSpace

Get-DisksSpace | Format-Table -Property * -auto | Out-File D:\DATA\SQL_Support\Report.txt 
==========================================================================================================
# Script for to get Disk space for all listed servers.
# It works after execute the Get-Diskspace funtion only. 
  
$servernames = get-content D:\Temp\Report.txt
foreach($server in $servernames)
{
Get-DisksSpace | Format-Table -Property * -wrap | Out-File D:\Temp\Report1.txt
}

==========================================================================================================

Get-WMIObject Win32_Volume -filter “DriveType=3” |
 Select SystemName,Caption,Label,@{Name=”DiskSize(GB)”;Expression={[decimal](“{0:N1}” -f($_.capacity/1gb))}},
@{Name=”freespace(GB)”;Expression={[decimal](“{0:N1}” -f($_.freespace/1gb))}},@{Name=”PercentFree(%)”;Expression={“{0:P2}” -f(($_.freespace/1gb)/($_.capacity/1gb))}}


==========================================================================================================
--Use Input files
$Servers = Get-Content D:\DATA\SQL_Support\Servers1.txt
foreach($srv in $Servers)
{ 
Get-WMIObject Win32_Volume -filter “DriveType=3” -computer $Srv | Select SystemName,Caption,Label,@{Name=”DiskSize(GB)”;Expression={[decimal](“{0:N1}” -f($_.capacity/1gb))}},@{Name=”freespace(GB)”;Expression={[decimal](“{0:N1}” -f($_.freespace/1gb))}},@{Name=”PercentFree(%)”;Expression={“{0:P2}” -f(($_.freespace/1gb)/($_.capacity/1gb))}} | ft -autosize
}
==========================================================================================================
get-wmiobject win32_volume | format-table name, label, freespace, capacity
==========================================================================================================
Get-WmiObject Win32_Volume -Filter "DriveType='3'" | ForEach { New-Object PSObject -Property @{
        Name = $_.Name
        Label = $_.Label
        FreeSpace_GB = ([Math]::Round($_.FreeSpace /1GB,2))
        TotalSize_GB = ([Math]::Round($_.Capacity /1GB,2))
    }
}
==========================================================================================================
##Diskspace details with status message

Get-WmiObject -computername "6.64.7.186" -query "select SystemName, DriveType, FileSystem, FreeSpace, Capacity, Label
from Win32_Volume where DriveType = 2 or DriveType = 3" | ForEach { New-Object PSObject -Property @{
        SystemName = $_.systemName
        LABEL = $_.Label
        SIZEInGB = ([Math]::Round($_.Capacity/1GB,2))
        UsedSizeInGB = ([Math]::Round($_.Capacity/1GB - $_.FreeSpace/1GB,2))
        FREESizeInGB = ([Math]::Round($_.FreeSpace/1GB,2))
        UsedPercentage =  ([Math]::Round(($_.Capacity/1GB - $_.FreeSpace/1GB)/($_.Capacity/1GB) * 100,2))
        FreePercentage = ([Math]::Round(($_.freespace/1GB)/ ($_.Capacity/1GB) * 100,2))
        DiskStatus = if(([Math]::Round(($_.freespace/1GB)/ ($_.Capacity/1GB) * 100)) -lt 20){'NOT HEALTHY' }else {'HEALTHY'}
    }}|ft SystemName,LABEL,SIZEInGB,UsedSizeInGB,FREESizeInGB,UsedPercentage,FreePercentage,DiskStatus -autosize
	
	
## With targetname 

Get-WmiObject -computername "EUDSQLKTOC402" -query "select SystemName, DriveType, FileSystem, FreeSpace, Capacity, Label,Caption
from Win32_Volume where DriveType = 2 or DriveType = 3" | ForEach { New-Object PSObject -Property @{
        SystemName = $_.systemName
        LABEL = $_.Label
        TargetName = $_.Caption
        SIZEInGB = ([Math]::Round($_.Capacity/1GB,2))
        UsedSizeInGB = ([Math]::Round($_.Capacity/1GB - $_.FreeSpace/1GB,2))
        FREESizeInGB = ([Math]::Round($_.FreeSpace/1GB,2))
        UsedPercentage =  ([Math]::Round(($_.Capacity/1GB - $_.FreeSpace/1GB)/($_.Capacity/1GB) * 100,2))
        FreePercentage = ([Math]::Round(($_.freespace/1GB)/ ($_.Capacity/1GB) * 100,2))
        DiskStatus = if(([Math]::Round(($_.freespace/1GB)/ ($_.Capacity/1GB) * 100)) -lt 20){'NOT HEALTHY' }else {'HEALTHY'}
    }}|ft SystemName,LABEL,TargetName,SIZEInGB,UsedSizeInGB,FREESizeInGB,UsedPercentage,FreePercentage,DiskStatus -autosize
==========================================================================================================
# Script for to get Disk space for all listed servers.  
$servernames = get-content C:\Temp\clusterservers.txt
foreach($server in $servernames)
{
Get-DisksSpace | Format-Table -Property * -wrap | Out-File D:\DATA\SQL_Support\Report.txt
}