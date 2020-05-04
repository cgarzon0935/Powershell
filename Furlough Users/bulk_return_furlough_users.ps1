
<############################################################################################################

Purpose: Reenables Furloughed employees in both Active Directory and Gsuite.

Assumes gam is setup on the local machine and script run in desktop PowerShell with
Active Directory administrator permissions already in place.

############################################################################################################>


$date = [datetime]::Today.ToString('dd-MM-yyyy')

# Path building
$path1 = "C:\path_of_log_file\"
$path2 = "name_of_log_$date.csv"
$pathFinal = $path1 + $path2
$FurloughList = Import-Csv -Delimiter "," -Path "C:\get_csv_file_here"

Import-Module ActiveDirectory

# Blank the console
# Clear-Host
Write-Host "********** Running MassAD-ReturnFurloughUsers ********** 

" 

foreach ($User in $FurloughList){

    # Clean User Input Data
    $sam = $User.FirstName.tolower().trim() + "." + $User.LastName.tolower().trim()

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

    Move-ADObject -Identity $dn -TargetPath "OU=Move_Those_Guys_here"
    Write-Host ("* " + $din + "'s Active Directory account moved to our Active Users OU") -ForegroundColor Yellow

    # Set password
    $Random = Get-Random -Minimum 10000 -Maximum 99999
    $TempPass = "Welcome_B@ck!" + $Random
    Set-ADAccountPassword -Reset -NewPassword (ConvertTo-SecureString -AsPlainText $TempPass -Force) $sam
    Set-aduser $sam -ChangePasswordAtLogon $true
    Write-Host ("* " + $din + "'s Active Directory password has been changed.") -ForegroundColor Yellow

    <# --- Start GSuite Account Modifications ---#>

    # Initialize the full path of GAM
    $gam=get_gam_dir.exe

    # Reenable gsuite account
    gam update user $email suspended off
    Write-Host ("* " + $din + "'s Gsuite Account has been enabled.") -ForegroundColor Yellow

    # Move account to the Active Users OU 
    gam update user $email ou 
    Write-Host ("* " + $din + "'s Gsuite Account moved to Active Employee OU.") -ForegroundColor Yellow

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

