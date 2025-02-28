# PowerShell script to set up deployment credentials

# Define variables
$appName = "ContosoDevExDevBox"
$displayName = "ContosoDevEx GitHub Actions Enterprise App"

# Function to set up deployment credentials
function Set-Up {
    param (
        [Parameter(Mandatory = $true)]
        [string]$appName,

        [Parameter(Mandatory = $true)]
        [string]$displayName
    )

    try {
        Write-Output "Starting setup for deployment credentials..."
        # Ensure the Azure CLI is installed and available
        if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
            Write-Host "Azure CLI is not installed or not available in the PATH. It will be installed now."
            # Install Azure CLI
            winget install Microsoft.AzureCLI -e --accept-source-agreements --accept-package-agreements
            if ($LASTEXITCODE -ne 0) {
                throw "Failed to install Azure CLI."
            }
        }
        else {
            winget upgrade Microsoft.AzureCLI -e --accept-source-agreements --accept-package-agreements
        }

        # Ensure azd is installed
        if (-not (Get-Command azd -ErrorAction SilentlyContinue)) {
            Write-Host "azd is not installed or not available in the PATH. It will be installed now."
            # Install azd
            winget install Microsoft.Azd -e --accept-source-agreements --accept-package-agreements
            if ($LASTEXITCODE -ne 0) {
                throw "Failed to install azd."
            }
        }
        else {
            winget upgrade Microsoft.Azd -e --accept-source-agreements --accept-package-agreements
        }

        .\Azure\createUsersAndAssignRole.ps1


        Write-Output "Deployment credentials set up successfully."
    }
    catch {
        Write-Error "Error during setup: $_"
        return 1
    }
}

# Main script execution
try {
    Clear-Host
    Set-Up -appName $appName -displayName $displayName
}
catch {
    Write-Error "Script execution failed: $_"
    exit 1
}