
<############################################################################################################

Purpose: Reenables Furloughed employees in both Active Directory and Gsuite.

Assumes gam is setup on the local machine and script run in desktop PowerShell with
Active Directory administrator permissions already in place.

############################################################################################################>


$date = [datetime]::Today.ToString('dd-MM-yyyy')

# Path building
$path1 = "C:\Automation\logs\"
$path2 = "AD_ReturnedFurloughUsers_$date.csv"
$pathFinal = $path1 + $path2
$FurloughList = Import-Csv -Delimiter "," -Path "C:\Automation\Furlough.csv"

Import-Module ActiveDirectory

# Blank the console
# Clear-Host
Write-Host "********** Running MassAD-ReturnFurloughUsers ********** 

" 

foreach ($User in $FurloughList){

    # Clean User Input Data
    $sam = $User.FirstName.tolower().trim() + "." + $User.LastName.tolower().trim()

    #get ad status - enabled and directory 
    #Get-ADUser $sam | Select -Property Enabled, DistinguishedName
     
    #get gsuite status - enabled and directory  
    #C:\GAM\gam.exe info user $email


    Write-Host (" Returning " +$sam+ " back to Snapsheet
    ")

    # Get the properties of the account and set variables
    $user = Get-ADuser $sam -properties canonicalName, distinguishedName, displayName, mail, manager | Select canonicalName, distinguishedName, displayName, mail, @{n="manager";e={(get-aduser -property emailaddress $_.manager).emailaddress}}
    $dn = $user.distinguishedName
    $cn = $user.canonicalName
    $din = $user.displayName
    $email = $user.mail
    $manager = $user.manager

    # Enable the account
    Enable-ADAccount $sam
    Write-Host ("* " + $din + "'s Active Directory account is enabled.") -ForegroundColor Yellow

    # Move account to the Active Users OU
    Move-ADObject -Identity $dn -TargetPath "OU=Users,OU=Internal,DC=snapsheet,DC=net"
    Write-Host ("* " + $din + "'s Active Directory account moved to 'Active Users' OU") -ForegroundColor Yellow

    # Set password
    $Random = Get-Random -Minimum 10000 -Maximum 99999
    $TempPass = "Welcome_B@ck!" + $Random
    Set-ADAccountPassword -Reset -NewPassword (ConvertTo-SecureString -AsPlainText $TempPass -Force) $sam
    Set-aduser $sam -ChangePasswordAtLogon $true
    Write-Host ("* " + $din + "'s Active Directory password has been changed.") -ForegroundColor Yellow

    <# --- Start GSuite Account Modifications ---#>

    # Initialize the full path of GAM
    $gam=C:\GAM\gam.exe

    # Reenable gsuite account
    gam update user $email suspended off
    Write-Host ("* " + $din + "'s Gsuite Account has been enabled.") -ForegroundColor Yellow

    # Move account to the Active Users OU 
    gam update user $email ou /Active_Employees
    Write-Host ("* " + $din + "'s Gsuite Account moved to /Active_Employees.") -ForegroundColor Yellow

    Write-Host ("
    ****************** Finished Processing " +$sam+ " ******************
        
    ")

    #output employee name and temp password
    $output = @()
    $output += New-Object psobject -Property @{Email=$email;Temp_pass=$TempPass}
    $output | export-csv -Path $pathFinal -NoTypeInformation -append
    # $output | ConvertTo-Csv -Delimiter ';' -NoTypeInformation | Export-Csv -path $pathFinal -Append
    # $output | Out-File $pathFinal -append
}

