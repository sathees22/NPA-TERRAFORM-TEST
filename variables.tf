variable "netbox_url" {
  description = "Base URL of the test NetBox instance."
  type        = string
  default     = "https://172.16.4.4"
}

variable "netbox_token" {
  description = "NetBox API token. Terraform will prompt for this if not supplied."
  type        = string
  sensitive   = true
}

