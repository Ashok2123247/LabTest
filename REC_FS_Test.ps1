<#
OUTPUT FORMAT
    =============================================================================
    FOLDERNAME || SIZE ||  ALLOCATED || FILES || FOLDERS || OWNER ||  PERMISSIONS
    =============================================================================   
#>
clear-host
$ErrorActionPreference = "Stop"
$Counting = 0
$Permissions =""
$PathDir = "C:\temp\"
Remove-Item -path $PathDir* -Recurse -Force -Include REC*.csv,Error*.log -ErrorAction Ignore 
$rootDir = Get-ChildItem -Force -directory "\\De35s024fsv01\c$\vol\vola0240121\vryynane"
$dt = get-date -format yyyyMMdd_HHmmss
$filedate = (Get-Date).tostring(“dd-MM-yyyy-Hmm”)

### CSV output
$filename = $pathDir + 'RECFS_Report' + $filedate + '.csv'
"FolderName; Size; Files; Folders; Owner; Permissions" | Out-File $filename -Append
$logFile = $PathDir + 'ErrorLogfile_' + $dt + ".log" 
$InputLines = ($rootDir| Measure-Object –Line).lines 

## Main loop
## Root folders size disply 
## -recurse for all subfolders info
foreach ($folderPath in $rootDir) 
{
$Counting += 1
Write-Progress -Activity "$counting.. $folderPath.. In progress" -PercentComplete ($Counting/$InputLines *100)

    $contents  = Get-ChildItem $folderPath.FullName -recurse -force -erroraction SilentlyContinue -Include * |` 
    Where-Object {$_.psiscontainer -eq $false} | Measure-Object -Property length -sum | Select-Object sum
    $Files = (Get-ChildItem $folderPath.FullName -recurse -Force -Include * ).count  
    $Folders = (Get-ChildItem $folderPath.fullname -recurse -Directory).count
    $Owner = (Get-Acl -Path $folderPath.FullName).Owner
    $sizeMB =($contents.sum /1MB).ToString("0.00")
    #$Permissions = (((Get-Acl -path $folderPath.FullName).Access).IdentityReference)
    #$Rights =  (((((Get-Acl -path $folderPath.FullName).Access).FileSystemRights) -replace('fullcontrol','[RWX]'))-replace('modify','[RW]'))-replace('Synchronize','[R]')

   
    $ac = Get-Acl -path $folderPath.FullName    
    foreach($Access in $ac.Access)
    {
    [string]$Permissions1 = $Access.IdentityReference
    $Permissions2 = (($Access.FileSystemRights) -replace('fullcontrol','[RWX]') -replace('modify','[RW]') -replace('Synchronize','[R]'))
    $Permissions3 = $Access.IsInherited 
    $Permissions = $Permissions1 + $Permissions2 + $Permissions3
    $Permissions    
    
    "$folderPath; $sizeMB; $Files; $Folders; $Owner; $Permissions"|out-file -Append $filename
    }

}
