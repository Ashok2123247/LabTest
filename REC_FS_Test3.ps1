<#
OUTPUT FORMAT
    =============================================================================
    FOLDERNAME || SIZE ||  ALLOCATED || FILES || FOLDERS || OWNER ||  PERMISSIONS
    =============================================================================   
#>
clear-host
$rootcount =0
$Counting = 0
$Permissions =""
$PathDir = "C:\temp\"
Remove-Item -path $PathDir* -Recurse -Force -Include REC*.csv,Error*.log -ErrorAction Ignore
<#
Write-Host "*********************************************************" -ForegroundColor Green
Write-Host "    Script will display root sub folders info only        " -ForegroundColor Yellow
Write-Host "    Share folder path :\\tuasnas03\commondata\           " -ForegroundColor Yellow
Write-Host "*********************************************************" -ForegroundColor Green  
write-host ""

#>

### CSV output
$filename = $pathDir + 'RECFS_Report' + $filedate + '.csv'
"Sharename;FolderName; Size; Files; Folders; Owner; Permissions(ID/FileRights/Inherited)" | Out-File $filename -Append
$logFile = $PathDir + 'ErrorLogfile_' + $dt + ".log" 
$dt = get-date -format yyyyMMdd_HHmmss
$filedate = (Get-Date).tostring(“dd-MM-yyyy-Hmm”)

$mainDir = Get-ChildItem -ErrorAction Ignore -Force -directory "\\tuasnas03\commondata\"

foreach($share in $mainDir )
{

Write-Progress -Activity "$rootcount.. $share ... In progress" -PercentComplete ($rootcount /($mainDir.count) * 100)
$rootcount +=1

        $subroot = get-childItem $share.FullName -Force -directory -ErrorAction Ignore |select -Unique
        foreach ($folderPath in $subroot) 
        {
        $folderPath1 = $folderPath.Name
        $sharename = $folderPath.Parent        
        
        try{
       
        $contents  = Get-ChildItem $folderPath.FullName -recurse -force -ErrorAction Ignore |` 
        Where-Object {$_.psiscontainer -eq $false} | Measure-Object -Property length -sum | Select-Object sum
        $Folders = (Get-ChildItem $folderPath.fullname -recurse -Directory).count
        $Files = (((Get-ChildItem $folderPath.FullName -recurse -force).count) - $Folders)
        $Owner = (Get-Acl -Path $folderPath.FullName).Owner
        $sizeMB =($contents.sum /1MB).ToString("0.00")
        #$Permissions = (((Get-Acl -path $folderPath.FullName).Access).IdentityReference)
        #$Rights =  (((((Get-Acl -path $folderPath.FullName).Access).FileSystemRights) -replace('fullcontrol','[RWX]'))-replace('modify','[RW]'))-replace('Synchronize','[R]')
       
        $ac = Get-Acl -path $folderPath.FullName    
        foreach($Access in $ac.Access)
        {
        [string]$Permissions1 = $Access.IdentityReference
        $Permissions2 = (($Access.FileSystemRights) -replace('fullcontrol','[RWX]') -replace('modify','[RW]') -replace('Synchronize','[R]')-replace('ReadAndExecute','[RX]'))
        $Permissions3 = $Access.IsInherited 
        $Permissions = $Permissions1 + $Permissions2 + $Permissions3

        "$sharename;$folderPath1; $sizeMB; $Files; $Folders; $Owner; $Permissions"
        "$sharename;$folderPath1; $sizeMB; $Files; $Folders; $Owner; $Permissions"|out-file -Append $filename
        
        }
        }catch{Write-Host "Access denied $folderPath"} 

        }
    
}

