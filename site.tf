resource "netbox_site" "terraform_lab" {
  name        = "Terraform Learning Lab"
  slug        = "terraform-learning-lab"
  status      = "staging"
  description = "Disposable site for a Terraform learning exercise."
}

output "terraform_lab_site_id" {
  description = "NetBox ID of the Terraform learning site."
  value       = netbox_site.terraform_lab.id
}
