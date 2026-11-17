# Commvault Remote Deployment Toolkit v2

Changes:
- Secure credential handling using Export-Clixml.
- No hosts file modification.
- Validates DNS resolution of proxy host.
- Validates connectivity to TCP 8452.
- If proxy entry is missing, installation is skipped and reported.
- Copies media and launches Setup.exe remotely.

Usage:
1. Copy Commvault media into Media folder.
2. Update Inventory/Servers.csv.
3. Run Scripts/Set-Credentials.ps1.
4. Run Scripts/Deploy-Commvault.ps1 as Administrator.
5. Review Reports/DeploymentReport.csv.
