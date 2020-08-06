# employeeoffboarding.ps1
# By Chris Garzon 

<############################################################################################################

Purpose: Off-board employees in both Active Directory and Gsuite.

Assumes gam is setup on the local machine and script run in desktop PowerShell with
Active Directory administrator permissions already in place.

############################################################################################################>


$date = [datetime]::Today.ToString('dd-MM-yyyy')

Import-Module ActiveDirectory

# Blank the console
# Clear-Host
Write-Host "Offboard a user

"

<# --- Active Directory account dispensation section --- #>

# Get the name of the account to disable from the admin
$sam = Read-Host 'Account Name of the user to deactivate (ex. rick.jones)'

# Get the properties of the account and set variables
$user = Get-ADuser $sam -properties canonicalName, distinguishedName, displayName, mail, manager | Select canonicalName, distinguishedName, displayName, mail, @{n="manager";e={(get-aduser -property emailaddress $_.manager).emailaddress}}
$dn = $user.distinguishedName
$cn = $user.canonicalName
$din = $user.displayName
$email = $user.mail
$manager = $user.manager

# Path building
$path1 = "C:\path_to_logs\"
$path2 = "AD-Suspended-User.csv"
$pathFinal = $path1 + $din + $path2

<# --- Start AD Account Management ---#>

Write-Host $din + "'s AD account disabled "; Disable-ADAccount $dn
Write-Host $din + "'s Moved to Disabled_Users OU"; Move-ADObject -Identity $dn -TargetPath "OU=dir_to_users,DC=org,DC=com"

<# --- Start GSuite Account Management ---#>

# Initialize the full path of GAM
$gam=C:\dir_to_dam\gam.exe

Write-host "Deleting Calendar Resource "; gam calendar $email wipe
Write-host "Deleting User "; gam delete user $email
Write-Host "Mischief Managed."