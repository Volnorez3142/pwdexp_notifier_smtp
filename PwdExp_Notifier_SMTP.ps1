#THIS BLOCK ELEVATES THE STARTED PS SESSION TO ADMIN (NEEDED FOR MANUAL RUN)
#if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
# if ([int](Get-CimInstance -Class Win32_OperatingSystem | Select-Object -ExpandProperty BuildNumber) -ge 6000) {
#  $CommandLine = "-File `"" + $MyInvocation.MyCommand.Path + "`" " + $MyInvocation.UnboundArguments
#  Start-Process -FilePath PowerShell.exe -Verb Runas -ArgumentList $CommandLine
#  Exit
# }
#}

#CHECKING AND CREATING THE NECESSARY DIRECTORIES, STARTING THE LOG
$test3142dir = Test-Path C:\by3142
$testpwnotifierdir = Test-Path C:\by3142\PasswordNotifier
if (-not $test3142dir) {
    Write-Host "No C:\by3142 directory found!" -ForegroundColor Red
    Write-Host "Creating C:\by3142 directory..." -ForegroundColor DarkGreen
    New-Item -Path "c:\" -Name "by3142" -ItemType "directory"
    Write-Host "Creating C:\by3142\PasswordNotifier directory..." -ForegroundColor DarkGreen
    New-Item -Path "c:\by3142" -Name "PasswordNotifier" -ItemType "directory"
} elseif (-not $testpwnotifierdir) {
    Write-Host "No C:\by3142\PasswordNotifier directory found!" -ForegroundColor Red
    Write-Host "Creating C:\by3142\PasswordNotifier directory..." -ForegroundColor DarkGreen
    New-Item -Path "c:\by3142" -Name "PasswordNotifier" -ItemType "directory"
} else {
    #ALL FINE, SKIPPING
}
$pwnotifierpath = "C:\by3142\PasswordNotifier\"
Start-Transcript -path C:\by3142\PasswordNotifier\SMTPNotificationLog_$(Get-Date -Format "yyyy-MM-dd_HHmmss").txt -append

#CREDS AND AUTH INFO FOR SMTP
$smtplogin = "3142@volnorez.lan"
$smtppw = "YOUR_PASSWORD"
$credentials = New-Object System.Management.Automation.PSCredential(
    $smtplogin,
    (ConvertTo-SecureString $smtppw -AsPlainText -Force)
)
$smtpserver = "smtp.volnorez.lan"
$smtpport = 587

#PARSING ALL THE ACTIVE USERS, SETTING THE NECESSARY VARIABLES
Import-Module ActiveDirectory
$vardistinguishedname = "*OU=Sakurada Space,OU=Volnorez,DC=sakurada,DC=lan"
$users = Get-ADUser -Filter * -Properties UserPrincipalName,pwdLastSet,PasswordNeverExpires,DistinguishedName | Where { ($_.Enabled -eq $True) -and ($_.DistinguishedName -like $vardistinguishedname) }

#CHECKING HOW MANY DAYS THERE IS LEFT TILL THE PASSWORD EXPIRES AND NOTIFYING THE USER
$users | ForEach-Object {
    Write-Host "=======================" -ForegroundColor Cyan
    $pso = Get-ADUserResultantPasswordPolicy -Identity $_.SamAccountName -ErrorAction SilentlyContinue
    $pwmaxage = if ($pso) { 
        $pso.MaxPasswordAge
    } else {
        (Get-ADDefaultDomainPasswordPolicy).MaxPasswordAge
    }
    $setdate = [DateTime]::FromFileTimeUtc([int64]$_.pwdLastSet)
    $exp = $setdate + $pwmaxage
    $daysleft = [math]::Floor(($exp.ToLocalTime() - (Get-Date)).TotalDays)
    Write-Host "Checking $($_.Name)..."
    Write-Host "Password expiration date:   $($exp.ToLocalTime())"
    Write-Host "Therefore there's           $daysleft days left."

    if (($daysleft -le 10) -and ($daysleft -gt -1)) {
        Write-Host "Sending email to $($_.UserPrincipalName)..." -ForegroundColor DarkGreen
        Send-MailMessage -To $_.UserPrincipalName `
             -From $smtplogin `
             -Subject "Password Expiration" `
             -Body "$($_.Name), your password will expire in $daysLeft days!
Please change it in your Microsoft account settings to prevent your user from getting locked.
Link: https://mysignins.microsoft.com/security-info/password/change `n`
THIS IS AN AUTOMATED EMAIL.
SYSTEM ADMINISTRATORS WILL NEVER ASK YOUR PASSWORD OR SEND YOU A QR CODE." `
             -SmtpServer $smtpserver `
             -Port $smtpport `
             -Credential $credentials `
             -UseSsl
     }
}

#STOPPING THE TRANSCRIPT AND CLEARING THE VARIABLES
Write-Output "
___.           ________  ____   _____ ________  
\_ |__ ___.__. \_____  \/_   | /  |  |\_____  \ 
 | __ <   |  |   _(__  < |   |/   |  |_/  ____/ 
 | \_\ \___  |  /       \|   /    ^   /       \ 
 |___  / ____| /______  /|___\____   |\_______ \
     \/\/             \/          |__|        \/ 
                        "
Stop-Transcript
Remove-Variable credentials,smtplogin,smtppw,users,pso,pwmaxage,setdate,exp,daysleft

