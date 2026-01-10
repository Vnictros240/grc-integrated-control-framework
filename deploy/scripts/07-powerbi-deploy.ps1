param (
    [string]$ConfigPath = "../config/dev.json"
)

$config = Get-Content -Path $ConfigPath | ConvertFrom-Json

Write-Host "Deploying Power BI Workspace: $($config.powerBi.workspaceName)" -ForegroundColor Cyan

# Requires MicrosoftPowerBIMgmt module
# Connect-PowerBIServiceAccount -ServicePrincipal ...

Write-Host "Power BI deployment stub executed." -ForegroundColor Yellow
