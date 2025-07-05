variable "resource_group_name" {
  type    = string
  default = "autoscale-rg"
}

variable "location" {
  type    = string
  default = "westus2"
}

variable "app_name" {
  type    = string
  default = "autoscale-healthcheck"
}

variable "app_service_plan_name" {
  type    = string
  default = "autoscale-plan"
}

variable "image_tag" {
  type        = string
  default     = "latest"
  description = "Docker image tag to deploy"
}

variable "use_existing_identity" {
  type        = bool
  default     = false
  description = "Whether to use existing user-assigned identity or create new one"
}