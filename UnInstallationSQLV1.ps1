<#

    To Uninstall SQL Instance by using powershell script
    Version 1
    Date : 22/1/2020

#>

Clear-host
Remove-Item -path "C:\temp\*" -Include SQLVersion*.ini -ErrorAction Ignore

$instance = Read-Host 'Instance Name ' 
$version = Read-Host 'SQL Version like 2012/2014/2016 '
$instance = $instance.ToUpper()

$CurrentDir = "C:\temp"
## Choose the Installation files path
$InstallerDirPath = "C:\temp\SQL2014\STD"
set-location $InstallerDirPath
$configFile = "$CurrentDir\SQLVersion_"+$version+"_"+$instance+"_Uninstall.ini"

## Function to create configure file
configFileCreation $instance | Out-File $configFile
try{
    Write-Progress -Activity "$instance  >> Uninstallation is in progress... " -PercentComplete (100/10 * 1)
    $installCmd = ".\setup.exe /Q /ACTION=Uninstall /IACCEPTSQLSERVERLICENSETERMS /ConfigurationFile=""$configFile""" 
    Invoke-Expression $installCmd
    write-host "Uninstallation has been completed on Instance >> " $instance  -ForegroundColor Green
}catch{ $ErrorMessage = $_.Exception.Message
        Write-Error -Message "Something problem" $ErrorMessage -ErrorAction Stop }
 
 
function configFileCreation ($instance) {
$config = "[OPTIONS]
HELP=""False""
INDICATEPROGRESS=""false""
X86=""False""
FEATURES=""SQLENGINE,REPLICATION,FULLTEXT""
INDICATEPROGRESS=""False""
X86=""False""
INSTANCENAME=""$instance""
"
$config
}
