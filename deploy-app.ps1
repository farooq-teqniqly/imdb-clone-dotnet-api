param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory=$true)]
    [string]$ContainerAppName,

    [Parameter(Mandatory=$true)]
    [string]$RegistryName,

    [Parameter(Mandatory=$false)]
    [string]$Location = "eastus",

    [Parameter(Mandatory=$false)]
    [string]$ImageName = "imdb-clone-api",

    [Parameter(Mandatory=$false)]
    [string]$Tag = "latest",

    [Parameter(Mandatory=$false)]
    [string]$EnvironmentName = "$ContainerAppName-env"
)

Write-Host "Starting deployment to Azure Container Apps..." -ForegroundColor Green

# Check if Azure CLI is logged in
az account show 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Error "Please login to Azure CLI first using 'az login'"
    exit 1
}

# Set subscription if needed (optional, user can set beforehand)
$currentSub = az account show --query "name" -o tsv
Write-Host "Using subscription: $currentSub" -ForegroundColor Cyan

# Create resource group if it doesn't exist
Write-Host "Ensuring resource group exists..." -ForegroundColor Yellow
az group create --name $ResourceGroupName --location $Location --output none 2>$null

# Create Azure Container Registry if it doesn't exist
Write-Host "Ensuring Azure Container Registry exists..." -ForegroundColor Yellow
az acr show --name $RegistryName --resource-group $ResourceGroupName --query "name" -o tsv 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Creating Azure Container Registry: $RegistryName" -ForegroundColor Yellow
    az acr create --resource-group $ResourceGroupName --name $RegistryName --sku Basic --output none
} else {
    Write-Host "Azure Container Registry $RegistryName already exists." -ForegroundColor Cyan
}

# Login to ACR
Write-Host "Logging in to Azure Container Registry..." -ForegroundColor Yellow
az acr login --name $RegistryName

# Build Docker image
Write-Host "Building Docker image..." -ForegroundColor Yellow
$fullImageName = "$RegistryName.azurecr.io/$ImageName`:$Tag"
docker build -t $fullImageName ./ImdbCloneApi
if ($LASTEXITCODE -ne 0) {
    Write-Error "Docker build failed"
    exit 1
}

# Push Docker image
Write-Host "Pushing Docker image to registry..." -ForegroundColor Yellow
docker push $fullImageName
if ($LASTEXITCODE -ne 0) {
    Write-Error "Docker push failed"
    exit 1
}

# Create Container Apps Environment if it doesn't exist
Write-Host "Ensuring Container Apps Environment exists..." -ForegroundColor Yellow
az containerapp env show --name $EnvironmentName --resource-group $ResourceGroupName --query "name" -o tsv 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Creating Container Apps Environment: $EnvironmentName" -ForegroundColor Yellow
    az containerapp env create --name $EnvironmentName --resource-group $ResourceGroupName --location $Location --output none
} else {
    Write-Host "Container Apps Environment $EnvironmentName already exists." -ForegroundColor Cyan
}

# Create or update Container App
Write-Host "Creating/updating Container App..." -ForegroundColor Yellow
az containerapp show --name $ContainerAppName --resource-group $ResourceGroupName --query "name" -o tsv 2>$null
if ($LASTEXITCODE -ne 0) {
    # Create new Container App
    Write-Host "Creating new Container App: $ContainerAppName" -ForegroundColor Yellow
    az containerapp create `
        --name $ContainerAppName `
        --resource-group $ResourceGroupName `
        --environment $EnvironmentName `
        --image $fullImageName `
        --target-port 8080 `
        --ingress external `
        --registry-server "$RegistryName.azurecr.io" `
        --registry-username $RegistryName `
        --registry-password $(az acr credential show --name $RegistryName --query "passwords[0].value" -o tsv) `
        --output none
} else {
    # Update existing Container App
    Write-Host "Updating existing Container App: $ContainerAppName" -ForegroundColor Yellow
    az containerapp update `
        --name $ContainerAppName `
        --resource-group $ResourceGroupName `
        --image $fullImageName `
        --registry-server "$RegistryName.azurecr.io" `
        --registry-username $RegistryName `
        --registry-password $(az acr credential show --name $RegistryName --query "passwords[0].value" -o tsv) `
        --output none
}

# Get the app URL
Write-Host "Retrieving Container App URL..." -ForegroundColor Yellow
$appUrl = az containerapp show --name $ContainerAppName --resource-group $ResourceGroupName --query "properties.configuration.ingress.fqdn" -o tsv
Write-Host "Deployment successful!" -ForegroundColor Green
Write-Host "Your API is available at: https://$appUrl" -ForegroundColor Cyan

Write-Host "Deployment completed." -ForegroundColor Green
