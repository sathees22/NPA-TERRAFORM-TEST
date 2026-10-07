terraform {
  required_providers {
    netbox = {
      source  = "e-breuninger/netbox"
      version = "~> 5.8.0"
    }
  }
}

provider "netbox" {
  server_url           = var.netbox_url
  api_token            = var.netbox_token
  allow_insecure_https = true
}
