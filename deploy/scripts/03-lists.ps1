param (
    [string]$ConfigPath = "../config/dev.json"
)

$config = Get-Content -Path $ConfigPath | ConvertFrom-Json

Write-Host "Provisioning Lists in $($config.sharePoint.siteUrl)" -ForegroundColor Cyan

# Connect specific site
Connect-PnPOnline -Url $config.sharePoint.siteUrl -ClientId $config.clientId -Tenant $config.tenantId -Thumbprint $config.certificateThumbprint

$lists = @(
    @{ Name = "Controls"; Template = "GenericList" },
    @{ Name = "FrameworkMappings"; Template = "GenericList" },
    @{ Name = "EvidenceRegister"; Template = "GenericList" },
    @{ Name = "POAM"; Template = "GenericList" }
)

foreach ($list in $lists) {
    if (!(Get-PnPList -Identity $list.Name -ErrorAction SilentlyContinue)) {
        New-PnPList -Title $list.Name -Template $list.Template
        Write-Host "Created list: $($list.Name)" -ForegroundColor Green
    } else {
        Write-Host "List $($list.Name) already exists." -ForegroundColor Yellow
    }
}

# TODO: Add fields and content types based on schemas
