param (
    [string]$ConfigPath = "../config/dev.json"
)

$config = Get-Content -Path $ConfigPath | ConvertFrom-Json

Write-Host "Connecting to tenant: $($config.tenantId)" -ForegroundColor Cyan

# Connect to Microsoft Graph
try {
    Connect-MgGraph -ClientId $config.clientId -TenantId $config.tenantId -CertificateThumbprint $config.certificateThumbprint
    Write-Host "Connected to Microsoft Graph" -ForegroundColor Green
}
catch {
    Write-Error "Failed to connect to Microsoft Graph: $_"
    exit 1
}

# Connect to SharePoint via PnP
try {
    $adminUrl = "https://$($config.sharePoint.siteUrl.Split('/')[2].Split('.')[0])-admin.sharepoint.com"
    Connect-PnPOnline -Url $adminUrl -ClientId $config.clientId -Tenant $config.tenantId -Thumbprint $config.certificateThumbprint
    Write-Host "Connected to SharePoint Online (Admin)" -ForegroundColor Green
}
catch {
    Write-Error "Failed to connect to SharePoint Online: $_"
    exit 1
}
