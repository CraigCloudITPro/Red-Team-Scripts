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

 Start-Sleep -Seconds 2
Function Test-PowerShellDownload {
    
    Write-host "Testing PowerShell Download via Web Client" -ForegroundColor Yellow
    $path = "$env:USERPROFILE\Desktop"
    $WebClient = New-Object System.Net.WebClient; $WebClient.DownloadFile("https://davescomputertips.com/wp-content/uploads/2014/01/windows-security-pwned-image-3-.jpg","$path\pwned1.jpg")
    Write-host "Testing PowerShell Download via Invoke-Webrequest" -ForegroundColor Yellow
    Invoke-WebRequest -Uri "https://davescomputertips.com/wp-content/uploads/2014/01/windows-security-pwned-image-3-.jpg" -OutFile "$path\pwned2.jpg"
    Start-Sleep -Seconds 2
    Write-Host "Opening Downloaded Images with MS Paint" -ForegroundColor Yellow
    Start-Sleep -Seconds 2
    & "C:\Windows\system32\mspaint.exe" "$path\pwned1.jpg" 
    & "C:\Windows\system32\mspaint.exe" "$path\pwned2.jpg" 
    Start-Sleep -Seconds 2
    taskkill.exe /IM mspaint.exe /F
    Write-host "Cleaning up downloaded items from Desktop" -ForegroundColor Yellow
    Remove-Item -Path "$path\pwned1.jpg" 
    Remove-Item -Path "$path\pwned2.jpg" 
    
}

Test-PowerShellDownload 
