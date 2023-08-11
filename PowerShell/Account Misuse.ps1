param(
    [Parameter(Mandatory=$true)]$ADAccount = "DemoUser" ## Enter the AD Account which can be moved into Domain Admins etc

)
Clear-Host
#### Check if PowerShell is open as Administrator ####
Function Check-IsElevated {
    $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $p = New-Object System.Security.Principal.WindowsPrincipal($id)
    if ($p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator))
   { Write-Output $true }      
    else
   { Write-Output $false }   
 }

 if (-not(Check-IsElevated))
 { throw Write-Host "Please run this script as an administrator" -ForegroundColor Red }

 Check-IsElevated

 #### Check if AD Module is installed ####
Function CheckModules($module) {
    $service = Get-Module -ListAvailable -Name $module
    if (-Not $service) {
        Install-Module -Name $module -Scope CurrentUser -Force
        Start-Sleep -Seconds 2
        Import-Module -Name $module
    }  
}
CheckModules("ActiveDirectory")

#### Checking Current User Active Directory Permissions ####
function validateDomainAdmin{
    $username = $env:USERNAME
    
        $domainAdmins=Get-ADGroupMember -Identity "Domain Admins" -Recursive | %{Get-ADUser -Identity $_.distinguishedName} | Where-Object {$_.Enabled -eq $True}
        $matchedAdmin=$username -in $domainAdmins.SamAccountName
        if($matchedAdmin){
            Write-Host "$username is a Domain Admin" -ForegroundColor Green
            }else{
           Write-Host "$username NOT a Domain Admin." -ForegroundColor Red
           }
    }
    
validateDomainAdmin

Function Test-AccountMisuse {

    Write-host "Testing Account Misuse" -ForegroundColor Yellow
    Import-Module -Name ActiveDirectory
    Add-ADGroupMember -Identity "Domain Admins" -Members $ADAccount -PassThru
    Add-ADGroupMember -Identity "Enterprise Admins" -Members $ADAccount -PassThru
    Add-ADGroupMember -Identity "Schema Admins" -Members $ADAccount -PassThru

    Start-Sleep -Seconds 2
    Write-host "Removing $ADAccount from Domain Admins, Enterprise Admins & Schema Admins" -ForegroundColor Yellow
    Remove-ADGroupMember -Identity "Domain Admins" -Members $ADAccount -PassThru
    Remove-ADGroupMember -Identity "Enterprise Admins" -Members $ADAccount -PassThru
    Remove-ADGroupMember -Identity "Schema Admins" -Members $ADAccount -PassThru
    
}

Test-AccountMisuse
