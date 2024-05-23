provider "azurerm" {
  features {}
}

provider "github" {
  token = var.github_token
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

# Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  address_space       = var.address_space
  location            = var.location
  resource_group_name = var.resource_group_name
}

# Subnet
resource "azurerm_subnet" "subnet" {
  name                 = var.subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet_prefix]
}

# Network Security Group
resource "azurerm_network_security_group" "nsg" {
  name                = "appServiceNSG"
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "AllowHTTPS"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowHTTP"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Associate NSG with Subnet
resource "azurerm_subnet_network_security_group_association" "subnet_nsg" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# App Service Plan
resource "azurerm_app_service_plan" "asp" {
  name                = var.app_service_plan
  location            = var.location
  resource_group_name = var.resource_group_name
  sku {
    tier = "Standard"
    size = "S1"
  }
}

# Create Azure Container Registry
resource "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Basic"
  admin_enabled       = true
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

# App Service
resource "azurerm_app_service" "app" {
  name                = var.app_service_name
  location            = var.location
  resource_group_name = var.resource_group_name
  app_service_plan_id = azurerm_app_service_plan.asp.id

  site_config {
    linux_fx_version = "DOCKER|${azurerm_container_registry.acr.login_server}/${var.acr_name}/aspnetapp:${var.docker_image_tag}"
  }

  identity {
    type = "SystemAssigned"
  }

  auth_settings {
    enabled = true
    default_provider = "AzureActiveDirectory"
    active_directory {
      client_id = var.client_id
    }
    token_store_enabled = true
  }

  depends_on = [azurerm_subnet_network_security_group_association.subnet_nsg]
}

output "app_url" {
  value = azurerm_app_service.app.default_site_hostname
}
