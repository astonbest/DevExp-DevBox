# PowerShell script to clean up Azure resources

# Exit immediately if a command exits with a non-zero status, treat unset variables as an error, and propagate errors in pipelines.
$ErrorActionPreference = "Stop"
$WarningPreference = "Stop"

# Azure Resource Group Names Constants
$solutionName = "DevExP"
$workloadResourceGroup = "DevExP-Workload-dev-rg"
$connectivityResourceGroup = "DevExP-Connectivity-dev-rg"
$managemwentResourceGroup = "DevExP-Management-dev-rg"
$computeResourceGroup = "DevExP-Compute-dev-rg"

# Function to delete a resource group
function Remove-ResourceGroup {
    param (
        [Parameter(Mandatory = $true)]
        [string]$resourceGroupName
    )

    try {
        $groupExists = (az group exists --name $resourceGroupName)

        if ($groupExists -eq "true") {
            # List and delete all deployments in the resource group
            $deployments = az deployment group list --resource-group $resourceGroupName --query "[].name" -o tsv
            foreach ($deployment in $deployments) {
                Write-Output "Deleting deployment: $deployment"
                az deployment group delete --resource-group $resourceGroupName --name $deployment
                Write-Output "Deployment $deployment deleted."
            }
            Start-Sleep -Seconds 10
            Write-Output "Deleting resource group: $resourceGroupName..."
            az group delete --name $resourceGroupName --yes --no-wait
            Write-Output "Resource group $resourceGroupName deletion initiated."
        }
        else {
            Write-Output "Resource group $resourceGroupName does not exist. Skipping deletion."
        }
    }
    catch {
        Write-Error "Error deleting resource group $resourceGroupName $_"
        return 1
    }
}

# Function to clean up resources
function Remove-Resources {
    try {
        Clear-Host
        Remove-ResourceGroup -resourceGroupName $workloadResourceGroup
        Remove-ResourceGroup -resourceGroupName $connectivityResourceGroup
        Remove-ResourceGroup -resourceGroupName $managemwentResourceGroup
        Remove-ResourceGroup -resourceGroupName $computeResourceGroup
        Remove-ResourceGroup -resourceGroupName "NetworkWatcherRG"
        Remove-ResourceGroup -resourceGroupName "Default-ActivityLogAlerts"
        Remove-ResourceGroup -resourceGroupName "DefaultResourceGroup-WUS2"
    }
    catch {
        Write-Error "Error during cleanup process: $_"
        return 1
    }
}

# Main script execution
try {
    Remove-Resources
}
catch {
    Write-Error "Script execution failed: $_"
    exit 1
}