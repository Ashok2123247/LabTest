Clear-host
Remove-Item -path "C:\temp\*" -Include SQLVersion*.ini -ErrorAction Ignore

function versionSelect (){

## SQL Version 2012, 2014, 2016, 2017, 2019 and etc
## Service pack

}

function EditionSelect (){

## Standard or Enterprise Edition (only 64 Bit version)

}

function prerequisitesSelect (){

## .Netframework version
## Installer files
## Key
## file location
## collation details 
## service account details 
## sa password
## Installation path 
## Current dir
## LogPath
## Instance details
## Version folder
## 
<#
$instance = Read-Host 'Enter Instance Name'
$instDrive = Read-host 'Enter SystemDB path (SY0)'
$userDbDrive = Read-host 'Enter UserDBData path (SD0)'
$userLogDrive = Read-host 'Enter userDBLog path (SL0)'
$tempDbDrive = Read-host 'Enter TempDB path (ST0)'
$backupDrive = Read-host 'Enter BackupDrive path (SS0)'
#>
<#
if ( -not $saPassword ) { 
	[System.Security.SecureString]$saPasswordSec = Read-Host "Enter the sa password: " -AsSecureString; 
	[String]$saPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($saPasswordSec)); 
} else { [String]$saPassword = $ServiceAccountPassword; } 
#>



$instance = "Test2"
$instDrive = "D:\DATA\SQL\SY0"
$userDbDrive = "D:\DATA\SQL\SD0"
$userLogDrive = "D:\DATA\SQL\SL0"
$tempDbDrive = "D:\DATA\SQL\ST0"
$backupDrive = "D:\DATA\SQL_Support\SS0"

$instance = $instance.ToUpper()
$hostName = get-content env:computername

if ( -not $ServiceAccountPassword ) { 
	[System.Security.SecureString]$ServiceAccountPassword = Read-Host "Enter the service account password: " -AsSecureString; 
	[String]$syncSvcAccountPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($ServiceAccountPassword)); 
} else { [String]$syncSvcAccountPassword = $ServiceAccountPassword; } 

if ( -not $saPassword ) { 
	[System.Security.SecureString]$saPasswordSec = Read-Host "Enter the sa password: " -AsSecureString; 
	[String]$saPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($saPasswordSec)); 
} else { [String]$saPassword = $ServiceAccountPassword; } 

}

function installType () {

## Standalone or Cluster 


}

function configFileCreation ($instance, $instDrive, $userDbDrive, $userLogDrive, $tempDbDrive, $backupDrive ) {
$config = "[OPTIONS]
UpdateEnabled=""true""
ERRORREPORTING=""False""
PID = ""P7FRV-Y6X6Y-Y8C6Q-TB4QR-DMTTK""
USEMICROSOFTUPDATE=""False""
FEATURES=""SQLENGINE,REPLICATION,FULLTEXT""
;with full feaures
;SQLENGINE,REPLICATION,FULLTEXT,RS,DQC,CONN,IS,BC,SDK,SSMS,ADV_SSMS
UpdateSource=""C:\temp\SQL2014\STD""
HELP=""False""
INDICATEPROGRESS=""false""
X86=""False""
INSTANCENAME=""$instance""
SQMREPORTING=""False""
INSTANCEID=""$instance""
INSTALLSHAREDDIR=""C:\Program Files\Microsoft SQL Server""
INSTALLSHAREDWOWDIR=""C:\Program Files (x86)\Microsoft SQL Server""
INSTANCEDIR=""C:\Program Files\Microsoft SQL Server""
FILESTREAMLEVEL=""0""
ENABLERANU=""False""
ADDCURRENTUSERASSQLADMIN=""False""
SQLCOLLATION=""SQL_Latin1_General_CP1_CI_AS""
SQLSYSADMINACCOUNTS=""KONENET\tsy_abazar""
SECURITYMODE=""SQL""
INSTALLSQLDATADIR="""+$instDrive+"\MSSQL12."+$instance+"\MSSQL\Data""
SQLUSERDBDIR="""+$userDbDrive+"\MSSQL12."+$instance+"\MSSQL\Data""
SQLUSERDBLOGDIR="""+$userLogDrive+"\MSSQL12."+$instance+"\MSSQL\Tlog""
SQLTEMPDBDIR="""+$tempDbDrive+"\MSSQL12."+$instance+"\MSSQL\Data""
SQLTEMPDBLOGDIR="""+$tempDbDrive+"\MSSQL12."+$instance+"\MSSQL\Tlog""
SQLBACKUPDIR="""+$backupDrive+"\MSSQL12."+$instance+"\MSSQL\Backup""
SQLSVCACCOUNT=""NT Service\MSSQL$""$Instance""
SQLSVCSTARTUPTYPE=""Automatic""
AGTSVCACCOUNT=""NT Service\SQLAgent$""$Instance""
AGTSVCSTARTUPTYPE=""Manual""
TCPENABLED=""1""
BROWSERSVCSTARTUPTYPE=""Automatic""
; Startup type for Integration Services
ISSVCACCOUNT=""NT Service\MsDtsServer120""
ISSVCSTARTUPTYPE=""Automatic""
;Reporting services
RSSVCACCOUNT=""NT Service\ReportServer$""$instance""
RSSVCSTARTUPTYPE=""Automatic""
"
$config
}

function SQLPatch () {
}

function portchange () {
}

function SQLADMIN_db_Creation (){
}

function monitoringLoginCreation(){
}

function addingUserLogins(){
}

##########################################################################
## Main File                                                            ##
##########################################################################

## Variable declaration

$CurrentDir = "C:\temp"
$InstallerDirPath = "C:\temp\SQL2014\STD"
set-location $InstallerDirPath

write-host "Creating Ini File for Installation..." -ForegroundColor green
$configFile = "$CurrentDir\SQLVersion_2014_"+$instance+"_install.ini"

## Function to create configure file
configFileCreation $instance $instDrive $userDbDrive $userLogDrive $tempDbDrive $backupDrive | Out-File $configFile
write-host "Configuration File written to $configFile"  -ForegroundColor Green

#######################################
# Starting SQL 2014 Base Installation #
#######################################

set-location $InstallerDirPath


#$installCmd = ".\setup.exe /ConfigurationFile=$($configfile)"
$installCmd = ".\setup.exe /Q /ACTION=UNINSTALL /IACCEPTSQLSERVERLICENSETERMS /SQLSVCPASSWORD=""$syncSvcAccountPassword"" /AGTSVCPASSWORD=""$syncSvcAccountPassword"" /SAPWD=""$saPassword"" /ConfigurationFile=""$configFile""" 
 

Invoke-Expression $installCmd 
 
