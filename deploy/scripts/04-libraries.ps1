param (
    [string]$ConfigPath = "../config/dev.json"
)

$config = Get-Content -Path $ConfigPath | ConvertFrom-Json

Write-Host "Provisioning Evidence Libraries in $($config.sharePoint.siteUrl)" -ForegroundColor Cyan

Connect-PnPOnline -Url $config.sharePoint.siteUrl -ClientId $config.clientId -Tenant $config.tenantId -Thumbprint $config.certificateThumbprint

$libName = "Evidence"

if (!(Get-PnPList -Identity $libName -ErrorAction SilentlyContinue)) {
    New-PnPList -Title $libName -Template DocumentLibrary
    Write-Host "Created library: $libName" -ForegroundColor Green
} else {
    Write-Host "Library $libName already exists." -ForegroundColor Yellow
}

# Example folder structure creation (Frameworks)
$frameworks = @("NIST 800-53", "CIS Controls", "CJIS", "HIPAA", "IRS Safeguards", "FERPA", "NERC CIP")

foreach ($fw in $frameworks) {
    Resolve-PnPFolder -List $libName -Folder $fw | Out-Null
    Write-Host "Ensured folder for $fw" -ForegroundColor Gray
}
