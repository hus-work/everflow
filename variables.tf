variable "github_token" {
  description = "GitHub personal access token."
  type        = string
}

variable "github_repo" {
  description = "GitHub repository containing the .NET application."
  type        = string
  default     = "dotnet/dotnet-docker"
}

variable "github_branch" {
  description = "Branch of the GitHub repository to fetch."
  type        = string
  default     = "main"
}

variable "acr_name" {
  description = "Name of the Azure Container Registry."
  type        = string
  default     = "myacrname"
}

variable "resource_group_name" {
  description = "Name of the resource group."
  type        = string
  default     = "myResourceGroup"
}

variable "app_service_plan" {
  description = "Name of the App Service Plan."
  type        = string
  default     = "myAppServicePlan"
}

variable "app_service_name" {
  description = "Name of the App Service."
  type        = string
  default     = "myAppServiceName"
}

variable "docker_image_tag" {
  description = "Tag for the Docker image."
  type        = string
  default     = "latest"
}

variable "vnet_name" {
  description = "Name of the Virtual Network."
  type        = string
  default     = "myVnet"
}

variable "subnet_name" {
  description = "Name of the Subnet."
  type        = string
  default     = "mySubnet"
}

variable "address_space" {
  description = "Address space for the Virtual Network."
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnet_prefix" {
  description = "Address prefix for the Subnet."
  type        = string
  default     = "10.0.1.0/24"
}

variable "location" {
  description = "Azure region for the resources."
  type        = string
  default     = "East US"
}

variable "client_id" {
  description = "Azure AD Client ID for App Service authentication."
  type        = string
}

variable "docker_image_tag" {
  default = "latest"
}