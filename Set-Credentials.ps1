$Credential = Get-Credential
$Credential | Export-Clixml "$PSScriptRoot\..\Config\AdminCred.xml"
Write-Host "Credential saved securely."
