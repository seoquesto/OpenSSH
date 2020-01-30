param (
    [string]$PublicKey
)

$url = "http://github.com/PowerShell/Win32-OpenSSH/releases/download/v8.1.0.0p1-Beta/OpenSSH-Win64.zip"

Write-Host 'Force use of TLS 1.2'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Write-Host 'Open 22'
New-NetFirewallRule -Name sshd -DisplayName 'OpenSSH Server (sshd)' -Profile @('Domain', 'Private', 'Public') -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22

Write-Host 'Download OpenSSH-Win64.zip'
New-Item -ItemType Directory C:\Downloads
Invoke-WebRequest $url -outfile C:\Downloads\OpenSSH-Win64.zip

Write-Host 'Unzip OpenSSH-Win64.zip and move to Program Files'
Expand-Archive -Path C:\Downloads\OpenSSH-Win64.zip -DestinationPath $Env:ProgramFiles -Force

Write-Host 'Install OpenSSH'
powershell.exe -ExecutionPolicy Bypass -File "C:\Program Files\OpenSSH-Win64\install-sshd.ps1"

Write-Host 'OpenSSH location to the PATH environment variable'
$env:Path="$env:Path;C:\Program Files\OpenSSH-Win64\"
Set-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH -Value $env:Path

Write-Host 'Start OpenSSH Service'
Start-Service sshd

Write-Host 'Change OpenSSH service startup type'
Set-Service sshd -StartupType Automatic

Write-Host 'Change OpenSSH Service configuration'
((Get-Content -path C:\ProgramData\ssh\sshd_config -Raw) `
-replace '#PubkeyAuthentication yes','PubkeyAuthentication yes' `
-replace '#StrictModes yes','StrictModes no' `
-replace '#PasswordAuthentication yes','PasswordAuthentication no' `
-replace 'Match Group administrators','#Match Group administrators' `
-replace 'AuthorizedKeysFile	.ssh/authorized_keys','AuthorizedKeysFile	C:\ProgramData\ssh\authorized_keys' `
-replace 'AuthorizedKeysFile __PROGRAMDATA__/ssh/administrators_authorized_keys','#AuthorizedKeysFile __PROGRAMDATA__/ssh/administrators_authorized_keys') | Set-Content -Path C:\ProgramData\ssh\sshd_config

Write-Host 'Restart OpenSSH service'
Restart-Service sshd

Write-Host 'Add public key to authorized_keys file'
Write-Output $PublicKey | Out-File C:\ProgramData\ssh\authorized_keys -Encoding ascii
