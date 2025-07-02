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