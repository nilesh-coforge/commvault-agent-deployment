
$Config = Get-Content "$PSScriptRoot\..\Config\settings.json" | ConvertFrom-Json
$Cred = Import-Clixml "$PSScriptRoot\..\Config\AdminCred.xml"
$Servers = Import-Csv "$PSScriptRoot\..\Inventory\Servers.csv"
$Results = @()

foreach ($Server in $Servers) {
    try {
        if (!(Test-Connection $Server.IPAddress -Count 2 -Quiet)) {
            throw "Ping failed"
        }

        $ProxyCheck = Invoke-Command -ComputerName $Server.ServerName -Credential $Cred -ScriptBlock {
            param($ProxyHost,$ProxyPort)
            try {
                Resolve-DnsName $ProxyHost -ErrorAction Stop | Out-Null
                $PortResult = Test-NetConnection -ComputerName $ProxyHost -Port $ProxyPort -InformationLevel Quiet
                if(-not $PortResult){
                    return @{ Status='Failed'; Message='Proxy reachable but port 8452 unavailable' }
                }
                return @{ Status='Success'; Message='Proxy validation successful' }
            }
            catch {
                return @{ Status='Failed'; Message='Proxy entry not found or DNS resolution failed' }
            }
        } -ArgumentList $Config.ProxyHost,$Config.ProxyPort

        if($ProxyCheck.Status -eq 'Failed'){
            $Results += [pscustomobject]@{
                Server = $Server.ServerName
                Status = 'Skipped'
                Reason = $ProxyCheck.Message
            }
            continue
        }

        Invoke-Command -ComputerName $Server.ServerName -Credential $Cred -ScriptBlock {
            param($InstallPath)
            New-Item -Path $InstallPath -ItemType Directory -Force | Out-Null
        } -ArgumentList $Config.InstallPath

        Copy-Item "$PSScriptRoot\..\Media\*" "\\$($Server.ServerName)\C$\Temp\Commvault" -Recurse -Force

        Invoke-Command -ComputerName $Server.ServerName -Credential $Cred -ScriptBlock {
            Start-Process 'C:\Temp\Commvault\Setup.exe'
        }

        $Results += [pscustomobject]@{
            Server = $Server.ServerName
            Status = 'Installer Launched'
            Reason = 'Success'
        }
    }
    catch {
        $Results += [pscustomobject]@{
            Server = $Server.ServerName
            Status = 'Failed'
            Reason = $_.Exception.Message
        }
    }
}

$Results | Export-Csv "$PSScriptRoot\..\Reports\DeploymentReport.csv" -NoTypeInformation
Write-Host 'Deployment completed. Review Reports\DeploymentReport.csv'
