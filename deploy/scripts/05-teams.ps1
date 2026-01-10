param (
    [string]$ConfigPath = "../config/dev.json"
)

$config = Get-Content -Path $ConfigPath | ConvertFrom-Json

Write-Host "Provisioning Teams: $($config.teams.teamName)" -ForegroundColor Cyan

Connect-MgGraph -ClientId $config.clientId -TenantId $config.tenantId -CertificateThumbprint $config.certificateThumbprint

$teamName = $config.teams.teamName

# Check if group exists
$group = Get-MgGroup -Filter "DisplayName eq '$teamName'" -ErrorAction SilentlyContinue

if (-not $group) {
    # Create M365 Group
    $group = New-MgGroup -DisplayName $teamName -MailNickname ($teamName -replace " ","") -MailEnabled:$true -SecurityEnabled:$false -GroupTypes "Unified"
    Write-Host "Created M365 Group with ID: $($group.Id)" -ForegroundColor Green
    
    # Enable Teams
    New-MgTeam -GroupId $group.Id
    Write-Host "Enabled Teams for Group" -ForegroundColor Green
} else {
    Write-Host "Team $teamName already exists." -ForegroundColor Yellow
}

# Create Channels
foreach ($channelName in $config.teams.channels) {
    if (-not (Get-MgTeamChannel -TeamId $group.Id -Filter "DisplayName eq '$channelName'" -ErrorAction SilentlyContinue)) {
        New-MgTeamChannel -TeamId $group.Id -DisplayName $channelName -MembershipType "Standard"
        Write-Host "Created channel: $channelName" -ForegroundColor Green
    }
}
