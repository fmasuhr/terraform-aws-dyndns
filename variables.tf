variable "authentication" {
  description = "Credentials used for authentication via basic auth."
  type = object({
    username = string
    password = string
  })
}

variable "domain_name" {
  description = "Domain name used for the record."
  type        = string
}

variable "name" {
  description = "Name used for resources."
  type        = string
}

variable "tags" {
  description = "Tags used for all created resources."
  type        = map(string)
  default     = {}
}

variable "zone_id" {
  description = "Route53 zone used for the record."
  type        = string
}
