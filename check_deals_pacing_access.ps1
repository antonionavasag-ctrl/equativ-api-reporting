# ============================================================
# Equativ API Access Checker
# Endpoint: /report/deals/pacing
# Purpose: Test which metrics and dimensions are available
# ============================================================


# ============================================================
# 1. Locate Source Python Script
# ============================================================

$reportePath = ".\reporte_deals.py"

if (!(Test-Path $reportePath)) {
    Write-Host "ERROR: Python source file not found."
    Write-Host "Expected file: reporte_deals.py"
    exit
}


# ============================================================
# 2. Read API Credentials from Python Script
# ============================================================

$scriptText = Get-Content $reportePath -Raw

$clientIdMatch = [regex]::Match($scriptText, 'CLIENT_ID\s*=\s*["'']([^"'']+)["'']')
$clientSecretMatch = [regex]::Match($scriptText, 'CLIENT_SECRET\s*=\s*["'']([^"'']+)["'']')

if (!$clientIdMatch.Success -or !$clientSecretMatch.Success) {
    Write-Host "ERROR: CLIENT_ID or CLIENT_SECRET could not be read."
    Write-Host "Check that the Python file contains:"
    Write-Host 'CLIENT_ID = "..."'
    Write-Host 'CLIENT_SECRET = "..."'
    exit
}

$CLIENT_ID = $clientIdMatch.Groups[1].Value.Trim()
$CLIENT_SECRET = $clientSecretMatch.Groups[1].Value.Trim()


# ============================================================
# 3. API URLs
# ============================================================

$TOKEN_URL = "https://login.eqtv.io/oauth2/token"
$REPORT_URL = "https://demand-api.eqtv.io/report/deals/pacing"


# ============================================================
# 4. Request Access Token
# ============================================================

Write-Host "Getting token..."

$tokenBody = @{
    grant_type    = "client_credentials"
    client_id     = $CLIENT_ID
    client_secret = $CLIENT_SECRET
}

try {
    $tokenResponse = Invoke-RestMethod `
        -Method Post `
        -Uri $TOKEN_URL `
        -Body $tokenBody `
        -ContentType "application/x-www-form-urlencoded"

    $token = $tokenResponse.access_token
}
catch {
    Write-Host "ERROR requesting token."
    Write-Host $_.Exception.Message
    exit
}

if (-not $token) {
    Write-Host "NO TOKEN"
    exit
}

Write-Host "TOKEN OK"
Write-Host ""


# ============================================================
# 5. Request Headers
# ============================================================

$headers = @{
    Authorization = "Bearer $token"
    Accept        = "application/json"
}


# ============================================================
# 6. Results Container
# ============================================================

$results = @()


# ============================================================
# 7. Function: Test Metric or Dimension
# ============================================================

function Test-DealsPacingField {
    param (
        [string]$Type,
        [string]$Name,
        [string[]]$Metrics,
        [string[]]$Dimensions
    )

    $payload = @{
        startDate  = "2026-06-07"
        endDate    = "2026-06-30"
        metrics    = $Metrics
        dimensions = $Dimensions
    } | ConvertTo-Json -Depth 10

    try {
        $response = Invoke-RestMethod `
            -Method Post `
            -Uri $REPORT_URL `
            -Headers $headers `
            -Body $payload `
            -ContentType "application/json"

        Write-Host "OK   - $Type - $Name"

        $script:results += [PSCustomObject]@{
            Type       = $Type
            Field      = $Name
            Status     = "OK"
            StatusCode = 200
            Detail     = ""
        }
    }
    catch {
        $statusCode = ""
        $detail = ""

        if ($_.Exception.Response) {
            $statusCode = $_.Exception.Response.StatusCode.value__
        }

        try {
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            $detail = $reader.ReadToEnd()
        }
        catch {
            $detail = $_.Exception.Message
        }

        Write-Host "FAIL - $Type - $Name - Status $statusCode"

        $script:results += [PSCustomObject]@{
            Type       = $Type
            Field      = $Name
            Status     = "FAIL"
            StatusCode = $statusCode
            Detail     = $detail
        }
    }
}


# ============================================================
# 8. Metrics to Test
# ============================================================

$metrics = @(
    "auctions",
    "bidRequests",
    "buyerSpendEuro",
    "clickRate",
    "clicks",
    "impressions",
    "ecpc",
    "smartGrossECpmEuro",
    "videoComplete",
    "completionRate",
    "viewabilityRate",
    "viewableImpressions",
    "companyVendorCostRate",
    "smartVendorCostRate",
    "managementVendorCostRate"
)


# ============================================================
# 9. Dimensions to Test
# ============================================================

$dimensions = @(
    "auctionPackageExternalDealId",
    "auctionPackageDealId",
    "auctionPackageDealName",
    "externalChildDealId",
    "childDealId",
    "childDealName",
    "winnerDealTypeId",
    "winnerDealTypeName",
    "countryId",
    "countryName",
    "creativeSize",
    "deviceTypeId",
    "deviceTypeName",
    "DspId",
    "DspName",
    "environmentTypeId",
    "environmentTypeName",
    "publisherId",
    "publisherName",
    "partnerId",
    "partnerName",
    "day",
    "hour",
    "week"
)


# ============================================================
# 10. Test Metrics
# ============================================================

Write-Host ""
Write-Host "TESTING DEALS/PACING METRICS"
Write-Host "============================"

foreach ($metric in $metrics) {
    Test-DealsPacingField `
        -Type "Metric" `
        -Name $metric `
        -Metrics @($metric) `
        -Dimensions @("auctionPackageDealName")
}


# ============================================================
# 11. Test Dimensions
# ============================================================

Write-Host ""
Write-Host "TESTING DEALS/PACING DIMENSIONS"
Write-Host "==============================="

foreach ($dimension in $dimensions) {
    Test-DealsPacingField `
        -Type "Dimension" `
        -Name $dimension `
        -Metrics @("impressions") `
        -Dimensions @($dimension)
}


# ============================================================
# 12. Export Results
# ============================================================

$results | Export-Csv `
    -Path .\deals_pacing_access_results.csv `
    -NoTypeInformation `
    -Encoding UTF8

Write-Host ""
Write-Host "Done."
Write-Host "Results saved to deals_pacing_access_results.csv"
