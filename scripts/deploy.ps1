param(
    [Parameter(Mandatory)]
    [string]$Suffix
)

$ResourceGroup = "rg-static-hosting"
$Location = "eastus"
$StorageAccount = "stportfolio$Suffix"
$CdnProfile = "cdn-portfolio"
$CdnEndpoint = "portfolio-$Suffix"
$SiteDir = Join-Path $PSScriptRoot "..\site"

# ── Phase 1: Resource Group & Storage Account ──────────────────────────────
Write-Host "`n=== Phase 1: Resource Group & Storage Account ===" -ForegroundColor Cyan

az group create `
    --name $ResourceGroup `
    --location $Location

az storage account create `
    --name $StorageAccount `
    --resource-group $ResourceGroup `
    --sku Standard_LRS `
    --kind StorageV2 `
    --location $Location

# ── Phase 2: Static Website Hosting & Upload ──────────────────────────────
Write-Host "`n=== Phase 2: Static Website Hosting ===" -ForegroundColor Cyan

az storage blob service-properties update `
    --account-name $StorageAccount `
    --static-website `
    --index-document index.html `
    --404-document 404.html

# SAFE TO RE-RUN: upload-batch with --overwrite replaces existing blobs
az storage blob upload-batch `
    --account-name $StorageAccount `
    --source $SiteDir `
    --destination '$web' `
    --overwrite

$originUrl = az storage account show `
    --name $StorageAccount `
    --resource-group $ResourceGroup `
    --query "primaryEndpoints.web" -o tsv
$originHost = ([System.Uri]$originUrl).Host

Write-Host "Storage static website URL: $originUrl" -ForegroundColor Green
Write-Host "Origin host (used for CDN): $originHost" -ForegroundColor Green

# ── Phase 3: CDN Profile & Endpoint ───────────────────────────────────────
Write-Host "`n=== Phase 3: CDN Profile & Endpoint ===" -ForegroundColor Cyan

az cdn profile create `
    --name $CdnProfile `
    --resource-group $ResourceGroup `
    --sku Standard_Microsoft

az cdn endpoint create `
    --name $CdnEndpoint `
    --profile-name $CdnProfile `
    --resource-group $ResourceGroup `
    --origin $originHost `
    --origin-host-header $originHost

# ── Phase 4: Cache Rules ───────────────────────────────────────────────────
Write-Host "`n=== Phase 4: Cache Rules ===" -ForegroundColor Cyan

# HTML: 1 hour (d:h:m:s = 0:1:0:0)
az cdn endpoint rule add `
    --name $CdnEndpoint `
    --profile-name $CdnProfile `
    --resource-group $ResourceGroup `
    --rule-name "HTMLCache" `
    --order 1 `
    --match-variable UrlFileExtension `
    --operator Equal `
    --match-values html `
    --action-name CacheExpiration `
    --cache-behavior Override `
    --cache-duration "0:1:0:0"

# Assets: 7 days (d:h:m:s = 7:0:0:0)
az cdn endpoint rule add `
    --name $CdnEndpoint `
    --profile-name $CdnProfile `
    --resource-group $ResourceGroup `
    --rule-name "AssetCache" `
    --order 2 `
    --match-variable UrlFileExtension `
    --operator Equal `
    --match-values css js svg png jpg ico `
    --action-name CacheExpiration `
    --cache-behavior Override `
    --cache-duration "7:0:0:0"

# ── Done ───────────────────────────────────────────────────────────────────
Write-Host "`n=== Provisioning Complete ===" -ForegroundColor Green
Write-Host "CDN endpoint: https://$CdnEndpoint.azureedge.net" -ForegroundColor Green
Write-Host ""
Write-Host "Wait 5-10 min for edge propagation, then verify:" -ForegroundColor Yellow
Write-Host "  curl -I https://$CdnEndpoint.azureedge.net" -ForegroundColor Yellow
Write-Host ""
Write-Host "To purge after content updates:" -ForegroundColor Yellow
Write-Host "  az cdn endpoint purge --name $CdnEndpoint --profile-name $CdnProfile --resource-group $ResourceGroup --content-paths '/*'" -ForegroundColor Yellow