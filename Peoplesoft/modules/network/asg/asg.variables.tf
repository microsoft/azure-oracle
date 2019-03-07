variable "resource_group_name" {
}
variable "location" {
}
variable "tags" {
  type = "map"
  
  default = {
    application = "Oracle Peoplesoft"
  }
}