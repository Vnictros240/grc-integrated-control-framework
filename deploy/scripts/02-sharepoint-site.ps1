param (
    [string]$ConfigPath = "../config/dev.json"
)

$config = Get-Content -Path $ConfigPath | ConvertFrom-Json

Write-Host "Provisioning SharePoint Site: $($config.sharePoint.siteUrl)" -ForegroundColor Cyan

try {
    $siteExists = Get-PnPTenantSite -Url $config.sharePoint.siteUrl -ErrorAction SilentlyContinue
    
    if ($siteExists) {
        Write-Host "Site already exists." -ForegroundColor Yellow
    } else {
        New-PnPTenantSite -Url $config.sharePoint.siteUrl `
                          -Title $config.sharePoint.siteTitle `
                          -Owner $config.sharePoint.ownerEmail `
                          -Template "STS#3" `
                          -TimeZone 10 
        Write-Host "Site created successfully." -ForegroundColor Green
    }
}
catch {
    Write-Error "Failed to provision SharePoint site: $_"
    exit 1
}
