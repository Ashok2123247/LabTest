<#

OUTPUT FORMAT
    ===================================================================================
    PARENTFOLDERNAME || FOLDERNAME || SIZE || FILES || FOLDERS || OWNER ||  PERMISSIONS
    ===================================================================================   
#>
clear-host
#GPEdit location:  Configuration>Administrative Templates>System>FileSystem 
#Set-ItemProperty 'HKLM:\System\CurrentControlSet\Control\FileSystem' -Name 'LongPathsEnabled' -value 1
$rootcount =0
$PathDir = "C:\temp\"
Remove-Item -path $PathDir* -Recurse -Force -Include REC*.csv,Error*.log -ErrorAction Ignore
### CSV output
$filename = $pathDir + 'RECFS_Report' + $filedate + '.csv'
"Sharename;FolderName; Size; Files; Folders; Owner; Permissions (ID/FileRights/Inherited)" | Out-File $filename -Append
$logFile = $PathDir + 'ErrorLogfile_' + $dt + ".log" 
$dt = get-date -format yyyyMMdd_HHmmss
$filedate = (Get-Date).tostring(“dd-MM-yyyy-Hmm”)

$mainDir = Get-ChildItem -ErrorAction Ignore -Force -directory "\\tuasnas03\commondata"

foreach($share in $mainDir )
{

Write-Progress -Activity "$rootcount.. $share ... In progress" -PercentComplete ($rootcount /($mainDir.count) * 100)
$rootcount +=1

        $folderPath1 = $share.Name
        $sharename = $share.Parent

        try
        {               
        $contents  = Get-ChildItem $share.FullName -recurse -force -ErrorAction SilentlyContinue -ErrorVariable err|` 
        Where-Object {$_.psiscontainer -eq $false} | Measure-Object -Property length -sum | Select-Object sum
        $Folders = (Get-ChildItem $share.FullName -recurse -Directory -ErrorAction SilentlyContinue -ErrorVariable err).count
        $Files = (((Get-ChildItem $share.FullName -recurse -force -ErrorAction SilentlyContinue -ErrorVariable err).count) - $Folders)        
        $Owner = (Get-Acl -Path $share.FullName).Owner
        $sizeMB =($contents.sum /1MB).ToString("0.00")
        $ac = Get-Acl -path $share.FullName   
            foreach($Access in $ac.Access)
            {
            [string]$Permissions1 = $Access.IdentityReference
            $Permissions2 = (($Access.FileSystemRights) -replace('fullcontrol','[R+W+X]') -replace('modify','[R+W]') `
            -replace('Synchronize','[R]')-replace('ReadAndExecute','[R+X]'))
            $Permissions3 = $Access.IsInherited 
            $Permissions = $Permissions1 + $Permissions2 + $Permissions3
            "$sharename;$folderPath1; $sizeMB; $Files; $Folders; $Owner; $Permissions"
            "$sharename;$folderPath1; $sizeMB; $Files; $Folders; $Owner; $Permissions"|out-file -Append $filename
            }        
        }catch{ if ($errorRecord.Exception -is [System.IO.PathTooLongException])
            {Write-Warning "Path too long in directory '$($errorRecord.TargetObject)'."
            $($errorRecord.TargetObject)|out-file -Append $logFile}
            else
            {Write-Error -ErrorRecord $errorRecord}
            } 
}
