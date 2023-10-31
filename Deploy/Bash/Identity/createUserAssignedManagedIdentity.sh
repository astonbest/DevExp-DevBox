#!/bin/bash

branch="main"

# Parameters
identityResourceGroupName="$1"
subscriptionId="$2"
identityName="$3"
customRoleName="$4"

# Constants
outputFilePath="./downloadedTempTemplates/identity/aibRoleImageCreation-template.json"
windows365IdentityName="0af06dc6-e4b5-4f28-818e-e78e62d137a5"
branch="main"
templateUrl="https://raw.githubusercontent.com/Evilazaro/MicrosoftDevBox/$branch/Deploy/ARMTemplates/identity/aibRoleImageCreation-template.json"

# Derive current user details
currentUser=$(az account show --query user.name -o tsv)
currentAzureUserId=$(az ad user show --id $currentUser --query id -o tsv)
identityId=$(az identity show --name $identityName --resource-group $identityResourceGroupName --query principalId -o tsv)

# Function to create a custom role using a template
createCustomRole() {
    local subId=$1
    local resourceGroup=$2
    local outputFile=$3
    local roleName=$4
    
    echo "Starting custom role creation..."
    echo "Downloading image template..."
    
    if ! wget --header="Cache-Control: no-cache" --header="Pragma: no-cache" "$templateUrl" -O "$outputFile"; then
        echo "Error: Failed to download the image template."
        exit 3
    fi
    
    echo "Template downloaded to $outputFile."
    echo "Role Name: $roleName"
    
    echo "Updating placeholders in the template..."
    sed -i "s/<subscriptionId>/$subId/g" "$outputFile"
    sed -i "s/<rgName>/$resourceGroup/g" "$outputFile"
    sed -i "s/<roleName>/$roleName/g" "$outputFile"
    
    if [ $? -ne 0 ]; then
        echo "Error updating placeholders."
        exit 4
    fi
    
    az role definition create --role-definition "$outputFile"
    echo "Custom role creation completed."
}

# Function to assign a role to an identity
assignRole() {
    local id=$1
    local roleName=$2
    local subId=$3

    echo "Assigning '$roleName' role to ID $id..."
    
    if az role assignment create --assignee-object-id "$id" --assignee-principal-type 'ServicePrincipal' --role "$roleName" --scope /subscriptions/"$subId"; then
        echo "Role '$roleName' assigned."
    else
        echo "Error assigning '$roleName'."
        exit 2
    fi
}

# Main script execution
echo "Script started."

createCustomRole "$subscriptionId" "$identityResourceGroupName" "$outputFilePath" "$customRoleName"

# Assign roles
assignRole "$identityId" "Virtual Machine Contributor" "$subscriptionId"
assignRole "$identityId" "Desktop Virtualization Contributor" "$subscriptionId"
assignRole "$identityId" "Desktop Virtualization Virtual Machine Contributor" "$subscriptionId"
assignRole "$identityId" "Desktop Virtualization Workspace Contributor" "$subscriptionId"
assignRole "$identityId" "Compute Gallery Sharing Admin" "$subscriptionId"
assignRole "$identityId" "Virtual Machine Local User Login" "$subscriptionId"
assignRole "$identityId" "Managed Identity Operator" "$subscriptionId"
assignRole "$identityId" "$customRoleName" "$subscriptionId"
assignRole "$windows365IdentityName" "Reader" "$subscriptionId"
assignRole "$currentAzureUserId" "DevCenter Dev Box User" "$subscriptionId"

echo "Script completed."
