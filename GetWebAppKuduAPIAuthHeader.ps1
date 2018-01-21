<#
.SYNOPSIS GetWebAppKuduAPIAuthHeader.ps1

 This script gets the Publishing Profile Credentials from the WebJobs Web App. and then it uses the Publishing Profile Credentials to get the Kudu REST API Authorization header and encode in Base64. 
.DESCRIPTION This script contains two functions. The functions perform the following:
 
 # 1 
 Get the Publishing Profile Credentials via PowerShell

 # 2
 Get the Kudu REST API Authorization header via PowerShell

 Reference: Functions from - https://blog.kloud.com.au/2016/08/11/monitoring-azure-web-jobs-health-with-application-insights by Paco de la Cruz.

 .PARAMETER resourceGroupName
 The resource group of the Web App. This is required.

 .PARAMETER webAppName
 The name of the Web App. This is required.

 .PARAMETER slotName
 The name of the deployment slot if needed. This is optional. 

 .PARAMETER subscriptionId
 The name of the proper Azure subscription ID. This is required.

.INPUTS  None
.OUTPUTS  None
.NOTES  Version:        1.0  Author:         Steve Buchanan  Creation Date:  1-18-18  Purpose/Change: Initial script development

.EXAMPLERun without parameters. You will still be prompted for required parameters. 
GetWebAppKuduAPIAuthHeader.ps1

.EXAMPLERun with parameters. GetWebAppKuduAPIAuthHeader.ps1 -resourceGroupName NAMEOFRESOURCEGROUP -webAppName NAMEOFWEBAPP -slotName NAMEOFSLOT -subscriptionId IDHERE
#>

# Parameters
param(
 [Parameter(Mandatory=$True)]
 [string]
 $resourceGroupName,

 [Parameter(Mandatory=$True)]
 [string]
 $webAppName,

 [string]
 $slotName
)

# Log into Azure
Login-AzureRmAccount

# Print Azure subscriptions
Get-AzureRmSubscription

# Prompt for entry of the subscription ID
Write-Host -NoNewline -ForegroundColor Cyan 'Enter your Subscription Id (List of Azure subscriptions above):'
$subscriptionId = Read-Host

# Sets the tenant, subscription, and environment for cmdlets to use in the current session. 
Set-AzureRmContext -SubscriptionId $SubscriptionId

# 1 Set the Get-AzureRmWebAppPublishingCredentials Function
function Get-AzureRmWebAppPublishingCredentials($resourceGroupName, $webAppName, $slotName = $null){
	if ([string]::IsNullOrWhiteSpace($slotName)){
		$resourceType = "Microsoft.Web/sites/config"
		$resourceName = "$webAppName/publishingcredentials"
	}
	else{
		$resourceType = "Microsoft.Web/sites/slots/config"
		$resourceName = "$webAppName/$slotName/publishingcredentials"
	}
	$publishingCredentials = Invoke-AzureRmResourceAction -ResourceGroupName $resourceGroupName -ResourceType $resourceType -ResourceName $resourceName -Action list -ApiVersion 2015-08-01 -Force
    	return $publishingCredentials
}

# 2 Set the Get-KuduApiAuthorisationHeaderValue Function
function Get-KuduApiAuthorisationHeaderValue($resourceGroupName, $webAppName, $slotName = $null){
    $publishingCredentials = Get-AzureRmWebAppPublishingCredentials $resourceGroupName $webAppName $slotName
    return ("Basic {0}" -f [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $publishingCredentials.Properties.PublishingUserName, $publishingCredentials.Properties.PublishingPassword))))
}

# Get the Publishing Profile Credentials via PowerShell
Get-AzureRmWebAppPublishingCredentials -resourceGroupName $resourceGroupName -webAppName $webAppName > $null

# Get the Kudu REST API Authorization header via PowerShell
$AuthorizationHeader = Get-KuduApiAuthorisationHeaderValue -resourceGroupName $resourceGroupName -webAppName $webAppName

# Output the encoded Authorization Header on the screen in yellow
Write-Host Your Authorization Header is: -ForegroundColor Green
Write-Host $AuthorizationHeader -ForegroundColor Yellow