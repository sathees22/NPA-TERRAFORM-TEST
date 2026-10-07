resource "netbox_site" "terraform_lab" {
  name        = "Terraform Lab Site01"
  slug        = "terraform-lab-site01"
  status      = "staging"
  description = "Created while learning Terraform; safe to remove from the test NetBox."
}

output "test_site_id" {
  description = "NetBox ID of the Terraform practice site."
  value       = netbox_site.terraform_lab.id
}
