provider "azurerm" {
  features {}
}

provider "github" {
  token = var.github_token
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

# Fetch .NET code from GitHub
resource "local_file" "aspnetapp_code" {
  content  = templatefile("${path.module}/scripts/fetch_code.sh", { 
    github_repo = var.github_repo,
    github_branch = var.github_branch 
  })
  filename = "${path.module}/scripts/fetch_code.sh"
}

resource "null_resource" "execute_fetch_code" {
  depends_on = [local_file.aspnetapp_code]

  provisioner "local-exec" {
    command = "bash ${path.module}/scripts/fetch_code.sh"
  }
}

# Build Docker Image
resource "docker_image" "aspnetapp" {
  name         = "${azurerm_container_registry.acr.login_server}/${var.acr_name}/aspnetapp:${var.docker_image_tag}"
  build {
    context    = "${path.module}/samples/aspnetapp"
    dockerfile = "${path.module}/samples/aspnetapp/Dockerfile"
  }
  depends_on = [null_resource.execute_fetch_code]
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
  depends_on = [docker_image.aspnetapp, azurerm_container_registry.acr]

  provisioner "local-exec" {
    command = <<EOT
      az acr login --name ${azurerm_container_registry.acr.name}
      docker push ${docker_image.aspnetapp.name}
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
    linux_fx_version = "DOCKER|${azurerm_container_registry.acr.login_server}/${var.acr_name}/aspnetapp:${var.docker_image_tag}"
  }
}

output "app_url" {
  value = azurerm_app_service.app.default_site_hostname
}
