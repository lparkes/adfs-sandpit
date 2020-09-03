#
# Windows PowerShell script for AD DS Deployment
#

Install-WindowsFeature AD-Domain-Services
# also pulls in 
# RSAT, RSAT-Role-Tools, RSAT-AD-Tools, RSAT-AD-PowerShell

Install-WindowsFeature RSAT-ADDS, RSAT-ADDS-Tools, RSAT-AD-AdminCenter, GPMC

Import-Module ADDSDeployment

$Secure_String_Pwd = ConvertTo-SecureString "SuperGreatPassword12!@" -AsPlainText -Force

Install-ADDSForest `
-CreateDnsDelegation:$false `
-DomainMode "Win2012R2" `
-DomainName "sandpit.local" `
-DomainNetbiosName "SANDPIT" `
-ForestMode "WinThreshold" `
-InstallDns:$true `
-NoRebootOnCompletion:$false `
-Force:$true `
-SafeModeAdministratorPassword $Secure_String_Pwd

# These are defaults for Install-ADDSForest that we don't ever need to mess with
#-DatabasePath "C:\windows\NTDS" `
#-LogPath "C:\windows\NTDS" `
#-SysvolPath "C:\windows\SYSVOL" `
