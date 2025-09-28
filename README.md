# IMDB Clone .NET API

A .NET API that provides IMDB-like functionality, deployed to Azure Container Apps.

## Prerequisites

- Azure CLI installed and logged in (`az login`)
- Docker installed
- PowerShell

## Deployment

Use the `deploy-app.ps1` script to build and deploy the API to Azure Container Apps.

### Parameters

- `ResourceGroupName` (required): Name of the Azure resource group
- `ContainerAppName` (required): Name for the container app
- `RegistryName` (required): Name for the Azure Container Registry
- `Location` (optional): Azure region (default: westus2)
- `ImageName` (optional): Docker image name (default: imdb-clone-api)
- `Tag` (optional): Docker image tag (default: latest)
- `EnvironmentName` (optional): Container Apps environment name (default: {ContainerAppName}-env)

### Example Usage

```powershell
.\deploy-app.ps1 -ResourceGroupName "my-resource-group" -ContainerAppName "imdb-api" -RegistryName "myregistry"
```

This will:

1. Create the resource group if it doesn't exist
2. Create an Azure Container Registry if it doesn't exist
3. Build the Docker image from the ImdbCloneApi directory
4. Push the image to the registry
5. Create or update the Azure Container App
6. Output the app URL

## API Usage

Once deployed, the API will be available at the provided URL. Refer to the API documentation or code for available endpoints.
