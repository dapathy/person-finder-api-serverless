[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [string]
    $subscription,
    [Parameter(Mandatory=$true)]
    [string]
    $resourceGroupName,
    [Parameter(Mandatory=$true)]
    [string]
    $serviceName
)

Connect-AzAccount -Subscription $subscription

$apiManagementContext = New-AzApiManagementContext -ResourceGroupName $resourceGroupName -ServiceName $serviceName

# Configure product
$productName = "unrestricted"
$product = Get-AzApiManagementProduct -Context $apiManagementContext -ProductId $productName -ErrorAction SilentlyContinue
$productArguments = @{
    Context = $apiManagementContext
    ProductId = $productName
    Title = "Unrestricted"
    Description = "No subscription required"
    SubscriptionRequired = $false
    State = "Published"
}
if ($product) {
    Set-AzApiManagementProduct @productArguments
} else {
    New-AzApiManagementProduct @productArguments
}

# Global policy
$policyPath = Join-Path "$(Get-Location)" "policy.xml"
Set-AzApiManagementPolicy -Context $apiManagementContext -PolicyFilePath $policyPath

# API version sets
$versionSetDirectories = Get-ChildItem -Directory
foreach ($versionSetDirectory in $versionSetDirectories) {
    $versionSetName = $versionSetDirectory.Name
    $versionSet = Get-AzApiManagementApiVersionSet -Context $apiManagementContext -ApiVersionSetId $versionSetName -ErrorAction SilentlyContinue
    $versionSetArguments = @{
        Context = $apiManagementContext
        ApiVersionSetId = $versionSetName
        Scheme = "Segment"
        Name = (Get-Culture).TextInfo.ToTitleCase($versionSetName)
    }
    if ($versionSet) {
        Set-AzApiManagementApiVersionSet @versionSetArguments
    } else {
        New-AzApiManagementApiVersionSet @versionSetArguments
    }

    # APIs
    $versionDirectories = Get-ChildItem -Directory -Path "$versionSetName"
    foreach ($versionDirectory in $versionDirectories) {
        $version = $versionDirectory.Name
        $jsonPath = Join-Path "$(Get-Location)" $versionSetName $version "openapi.json"
        $apiArguments = @{
            Context = $apiManagementContext
            ApiId = "$versionSetName-$version"
            ApiType = "Http"
            ApiVersionSetId = $versionSetName
            ApiVersion = $version
            Path = "users"
            Protocol = "Https"
            SpecificationFormat = "OpenApiJson"
            SpecificationPath = $jsonPath
        }
        $api = Import-AzApiManagementApi @apiArguments
        Add-AzApiManagementApiToProduct -Context $apiManagementContext -ProductId $productName -ApiId $api.ApiId
    }
}