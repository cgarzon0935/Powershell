
<############################################################################################################

Purpose: Update Furlough Users with Hire Date (description)

Assumes script runs in Powershelle with AD permissions already in place

############################################################################################################>

# import module to configure ad objects 
Import-Module ActiveDirectory

#get date 
$modified_date = Get-Date -UFormat "%D %I:%M"

#get/set paths
$path_dir = "C:\directory_to_script_folder\"
$log_file = "log_changes.csv"
$pathFinal = $path_dir + $log_file
$FurloughList = Import-Csv -Delimiter "," -Path "C:\descriptions.csv"

foreach ($user in $FurloughList){
   
    #get the users data from csv file
    $email_addr = $user.'Email '
    $hire_date = $user.'Description '

    # get user | if user exist, update description
    Get-aduser -filter {mail -eq $email_addr} | Set-ADUser -Description $hire_date

    #output employee name and log file
    $output = @()
    $output += New-Object psobject -Property @{Email=$email_addr;Modified=$modified_date}
    $output | export-csv -Path $pathFinal -NoTypeInformation -append
}