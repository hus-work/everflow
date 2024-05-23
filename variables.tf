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
  default = "latest"
}