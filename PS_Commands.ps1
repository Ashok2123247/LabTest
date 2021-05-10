## ExecutionPolicy

Set-ExecutionPolicy -ExecutionPolicy Unrestricted 

## Service Details with Service account ##

gwmi win32_service -computerName EUDVMMSSQL100  |` 
where {$_.Displayname -like "SQL Server*" -and $_.Displayname -notlike "*Browser*" -and $_.Displayname -notlike "*Writer*" `
-and $_.Displayname -notlike "*Integration*" } |`
ForEach {
New-Object PSObject -Property @{
‘Service Name’ = $_.Name
‘Start Mode’ = $_.Startmode
‘Service Account Name’ = $_.Startname
‘State’ = $_.State
‘Status’= $_.Status
‘System Name’ = $_.Systemname
} 
} |ft -AutoSize


===========================================================================================



(get-itemproperty 'HKLM:\software\microsoft\microsoft sql server').InstalledInstances

Get-LocalGroupMember administrators |select name |findstr "abazar"