variable "location" {
  description = "(Required) The location/region where the core network will be created. The full list of Azure regions can be found at https://azure.microsoft.com/regions"
}

variable "resource_group_name" {
  description = "(Required) The name of the resource group where the load balancer resources will be placed."
}

variable "prefix" {
  description = "(Required) Default prefix to use with your resource names."
  default     = "azure_lb"
}
variable "lb_sku" {
    default = "Standard"

}
variable "lb_port" {
  description = "Protocols to be used for lb health probes and rules. [frontend_port, protocol, backend_port]"
  default     = {}
}

variable "lb_probe_unhealthy_threshold" {
  description = "Number of times the load balancer health probe has an unsuccessful attempt before considering the endpoint unhealthy."
  default     = 2
}

variable "lb_probe_interval" {
  description = "Interval in seconds the load balancer health probe rule does a check"
  default     = 5
}

variable "frontend_name" {
  description = "(Required) Specifies the name of the frontend ip configuration."
  default = "web-lb"
}

variable "public_ip_address_allocation" {
  description = "(Required) Defines how an IP address is assigned. Options are Static or Dynamic."
  default = "Static"
}

variable "tags" {
    description = "ARM resource tags to any resource types which accept tags"
    type = "map"
}

variable "type" {
  type        = "string"
  description = "(Optional) Defined if the loadbalancer is private or public"
  default     = "Public"
}

variable "frontend_subnet_id" {
  description = "(Optional) Frontend subnet id to use when in private mode"
}
