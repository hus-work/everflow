provider "azurerm" {
  features {}
}

provider "github" {
  token = var.github_token
}

# Fetch .NET code from GitHub
resource "null_resource" "fetch_code" {
  provisioner "local-exec" {
    command = <<EOT
      git clone --depth 1 --branch ${var.github_branch} https://github.com/${var.github_repo}.git
      cd ${basename(path.module)}/samples/aspnetapp
      dotnet restore
      dotnet build --configuration Release
      docker build -t ${azurerm_container_registry.acr.login_server}/${var.acr_name}/aspnetapp:latest .
    EOT
  }
}

# Create Azure Container Registry
resource "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = var.resource_group_name
  location            = "East US"
  sku                 = "Basic"
  admin_enabled       = true
}

# Store Docker image in Azure Container Registry
resource "null_resource" "docker_push" {
  depends_on = [azurerm_container_registry.acr, null_resource.fetch_code]
  provisioner "local-exec" {
    command = <<EOT
      az acr login --name ${azurerm_container_registry.acr.name}
      docker push ${azurerm_container_registry.acr.login_server}/${var.acr_name}/aspnetapp:latest
    EOT
  }
}

# Create App Service Plan
resource "azurerm_app_service_plan" "asp" {
  name                = var.app_service_plan
  location            = "East US"
  resource_group_name = var.resource_group_name
  sku {
    tier = "Standard"
    size = "S1"
  }
}

# Create App Service
resource "azurerm_app_service" "app" {
  name                = var.app_service_name
  location            = "East US"
  resource_group_name = var.resource_group_name
  app_service_plan_id = azurerm_app_service_plan.asp.id

  site_config {
    linux_fx_version = "DOCKER|${azurerm_container_registry.acr.login_server}/${var.acr_name}/aspnetapp:latest"
  }
}

output "app_url" {
  value = azurerm_app_service.app.default_site_hostname
}
