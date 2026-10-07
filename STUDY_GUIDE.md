# Terraform Study Guide: NetBox Lab

This guide uses the test NetBox at `https://172.16.4.4` and the small Terraform
project in this folder. The exercises build on the current `netbox_site`
resource. Use a disposable test NetBox and a token with only the permissions
needed for the exercises.

## 1. What Terraform does

Terraform compares three things:

1. **Configuration**: the desired resources in `.tf` files.
2. **State**: Terraform's record of resources it manages.
3. **Remote system**: the actual objects in NetBox.

`terraform plan` previews the difference. `terraform apply` asks NetBox to make
that difference real. Terraform is declarative: describe the desired result,
not a sequence of API calls.

## 2. First run

Open PowerShell in this project folder:

```powershell
Set-Location C:\NPA\WRK\terraform\terrafor_test_netbox
terraform init
terraform fmt
terraform validate
terraform plan
```

Terraform prompts for `netbox_token` because it is a required sensitive
variable. Enter a token for the test instance; do not put it in `main.tf`, a
committed `.tfvars` file, or chat.

Review the plan before approving anything. The starter configuration should
propose one staging site named `Terraform Lab Site`, with slug
`terraform-lab-site`. If the plan shows unrelated resources or destructive
actions, stop and investigate.

When the target and plan are correct:

```powershell
terraform apply
```

Type `yes` only after reviewing the plan shown by `apply`.

## 3. Useful inspection commands

```powershell
terraform state list
terraform state show netbox_site.terraform_lab
terraform output
terraform show
```

The state file contains resource details and may contain sensitive values.
Keep it private; this project's `.gitignore` excludes state and `.tfvars`
files.

## 4. Practice cases

Do each case in order. Run `terraform fmt`, `terraform validate`, and
`terraform plan` after each configuration change. Apply only to the test
instance, after reviewing the complete plan.

### Case A — Change a site description

**Goal:** Learn how configuration changes create an update plan.

1. In `main.tf`, change the description on `netbox_site.terraform_lab`.
2. Run `terraform plan`.
3. Identify the proposed action. It should update the existing site rather
   than create a second one.
4. Apply, then inspect the resource with `terraform state show`.

**Think about:** What did Terraform use to know this is the same site? What
would happen if you changed the resource label from `terraform_lab` to another
name?

### Case B — Make the site name configurable

**Goal:** Use input variables instead of repeating fixed values.

1. Add a `site_name` string variable in `variables.tf`.
2. Replace the literal `name` in the site resource with `var.site_name`.
3. Set a safe default or supply a value interactively.
4. Run `terraform plan` and observe the result.

For a non-secret value, a local `terraform.tfvars` file is convenient, but
`.tfvars` files are ignored by Git here. Do not put tokens in it.

### Case C — Add a VLAN to the practice site

**Goal:** Reference one managed resource from another.

Add this resource to `main.tf`:

```hcl
resource "netbox_vlan" "practice" {
  name    = "Terraform Practice VLAN"
  vid     = 3999
  site_id = netbox_site.terraform_lab.id
  status  = "active"
}
```

Before applying, check that VLAN ID `3999` is unused in the test NetBox. The
`site_id` reference creates an implicit dependency: Terraform creates the site
before creating the VLAN.

**Think about:** How does the plan change if you remove `site_id`? Which
resource has to exist first?

### Case D — Read and explain a plan

**Goal:** Practice reviewing plans before approving them.

1. Change the VLAN name or description.
2. Run `terraform plan`.
3. Record whether Terraform plans an in-place update, replacement, creation, or
   deletion.
4. Explain why before running `apply`.

Never assume every change is an in-place update. A replacement can destroy an
existing object and create a new one.

### Case E — Import an existing test site

**Goal:** Bring an object created outside Terraform under Terraform management.

1. Pick a disposable site in the test NetBox and find its numeric NetBox ID.
2. Write a matching `netbox_site` resource in configuration first.
3. Import it using that resource address:

   ```powershell
   terraform import netbox_site.terraform_lab <numeric-site-id>
   ```

4. Run `terraform plan`. Adjust configuration until the plan does not propose
   unwanted changes.

Import records an existing object in state; it does not create a duplicate.
Do not import a production site into a practice state.

### Case F — Safely clean up the lab

**Goal:** Understand resource deletion and the scope of state.

Run:

```powershell
terraform plan -destroy
```

Read the complete plan. `terraform destroy` deletes resources managed by this
project from the configured NetBox. Do not run it unless the resources are
disposable and the plan contains only the lab objects you intend to remove.

## 5. Safety checklist

- Check that the URL is `https://172.16.4.4` before planning or applying.
- Use a dedicated test token, and rotate it if it is exposed.
- `sensitive = true` hides a token in normal CLI output; it does not keep secrets
  out of Terraform state or provider logs.
- Back up state before manually changing or moving it. Prefer `terraform
  state mv` and `terraform state rm` only when you understand their effects.
- Never delete the state file to “reset” Terraform. It can leave real NetBox
  objects unmanaged.
- Avoid `-auto-approve` while learning.
- `allow_insecure_https = true` skips TLS certificate verification. For regular
  use, install/trust the NetBox certificate CA and disable this setting.

## 6. Provider compatibility note

This project currently pins `e-breuninger/netbox` `~> 3.10.0`. That provider
version was tested with NetBox 4.1.0–4.1.11. If the test instance is on a newer
NetBox version, Terraform may warn or encounter provider/API incompatibilities.
Check the provider's supported-version table before changing the version
constraint; after changing it, run `terraform init -upgrade`, `terraform
validate`, and a reviewed plan.

## 7. A repeatable workflow

For each exercise, use this sequence:

```powershell
terraform fmt
terraform validate
terraform plan
# Review the plan, then only if it is correct:
terraform apply
terraform state list
```

Change one thing at a time and explain the plan before approving it. This makes
it easier to connect HCL configuration to Terraform's behavior.
