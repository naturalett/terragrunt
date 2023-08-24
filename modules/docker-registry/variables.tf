variable "namespace" { default = "" }
variable "node_selector" { default = "" }
variable "docker_registry_host" { default = "" }
variable "proxyPassword" { default = "" }
variable "proxyUsername" { default = "" }

variable "ingress_class" { default = "" }
variable "organization" { default = "" }
variable "domain_name" { default = "" }
variable "enabled_ingress" { default = false }

locals {
  deploy_ingress = var.enabled_ingress
  labels = {
    "app.kubernetes.io/name"     = "docker-registry"
    "helm.sh/chart"              = "docker-registry"
    "app.kubernetes.io/instance" = "docker-registry"

  }
  env = flatten([
    for name, value in var.environment : {
      name  = tostring(name)
      value = tostring(value)
    }
  ])
}

variable "name" { default = "docker-registry" }
variable "image_tag" { default = "2.7.1" }

variable "environment" {
  type        = map(string)
  description = "(Optional) Name and value pairs to set in the container's environment"
  default     = {}
}

variable "volume_name" { default = "" }
variable "mount_path" { default = "" }
variable "claim_name" { default = "" }
