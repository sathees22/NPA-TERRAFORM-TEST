# NetBox, Terraform, and Git: Step-by-Step Lab

This is a hands-on course for the test NetBox at `https://172.16.4.4`, using
the Terraform project in this directory and its existing Git repository.
Follow one lesson at a time. Ask for the next lesson after you complete the
current one; do not run every example in one session.

## Important: protect the lab first

- The NetBox inventory was cleaned out, but always check the live system before
  changing it. Another administrator or process may have added data.
- The root Terraform configuration currently contains **no NetBox resources**.
  It will not recreate the deleted practice site. Lesson 5 has an example to
  add only when you are ready to practice.
- Use a dedicated test NetBox API token with only the permissions required for
  the current lesson. Never paste a token into chat, source files, Git, or a
  screenshot. A token previously shared during setup should be rotated before
  future use.
- `terraform.tfvars`, state files, plans, and `.env` files are ignored by Git.
  Keep them local and private anyway: Terraform state can contain secrets.
- The provider currently allows insecure HTTPS for the self-signed test
  certificate. That is for this isolated lab only; it does not make the
  connection safe from interception. Use a trusted CA certificate for regular
  use.
- Never use `terraform apply`, `terraform destroy`, bulk API writes, or Git
  `push` until you have inspected exactly what the command will do.

## Course roadmap

| Stage | Topics | Result |
|---|---|---|
| 1 | Git status, diff, branches, commits | Safely track changes |
| 2 | NetBox UI, sites, locations, devices, IPAM | Understand the inventory model |
| 3 | NetBox API and permissions | Read NetBox without changing it |
| 4 | Terraform configuration, providers, variables | Understand the project files |
| 5 | First Terraform-managed site | Plan, apply, verify, and destroy one lab object |
| 6 | VLANs, prefixes, and IP addresses | Model related IPAM objects in dependency order |
| 7 | Terraform state, import, drift | Understand what Terraform manages |
| 8 | Git branches and review workflow | Practice changes without risking `main` |
| 9 | Modules, environments, and remote state | Learn reusable/team Terraform patterns |
| 10 | Capstone and review | Build a small, documented NetBox lab |

## Stage 1 — Git foundations

Git is already initialized in this folder. The current branch is `main`, and
the repository has an `origin` remote. For now, work locally; do not push to
GitHub during the exercises.

Open PowerShell:

```powershell
Set-Location C:\NPA\WRK\terraform\NPA-TERRAFORM-TEST
git status
git branch --show-current
git log -1 --oneline
```

Learn these commands before editing anything:

```powershell
git status                 # What changed?
git diff                   # What exactly changed?
git diff --check           # Find whitespace mistakes
git branch                 # List local branches
```

Git's three important places:

1. **Working tree**: the files you are editing.
2. **Staging area**: changes selected with `git add`.
3. **Commit history**: saved snapshots created with `git commit`.

After an intentional lesson change, inspect it, then stage only the file(s)
you mean to save:

```powershell
git status
git diff
git add STUDY_GUIDE.md
git diff --cached
git commit -m "docs: record lesson progress"
```

Do not copy these commit commands blindly. First inspect the diff and make
sure no `.tfvars`, state, plan, or secret file is staged. Do not use `git
add .` until you can explain every file it would include.

**Exercise:** Run the first four commands above. Confirm you understand the
branch name and the latest commit. For the current course edits, review
`git status` and `git diff`; don't commit or push until you want to preserve
this course update.

## Stage 2 — NetBox concepts

NetBox is a source of truth for network inventory and relationships. Start
with the UI, not with writes.

1. Sign in to the test NetBox and confirm the URL is `https://172.16.4.4`.
2. Find the menus for **Organization**, **Devices**, **IPAM**,
   **Virtualization**, and **VPN**.
3. Learn how a site relates to locations, racks, devices, interfaces, and
   assigned IP addresses.
4. Learn the IPAM hierarchy: VRF (optional) → prefix → IP address. VLANs can
   be associated with sites and prefixes.
5. Use list views and filters to inspect objects. Do not create or delete
   anything during this stage.

**Exercise:** In the UI, check whether sites, devices, prefixes, VLANs, and IP
addresses currently exist. Record counts only in your private notes. Ask
before changing the live inventory.

## Stage 3 — Read-only API practice

The REST API lets tools inspect or change NetBox. An API token grants
permissions; it is a secret, not a password to share.

Use a read-only token where possible. In PowerShell, enter the token into a
hidden prompt rather than putting it into the command history:

```powershell
$secureToken = Read-Host "NetBox API token" -AsSecureString
$token = [System.Net.NetworkCredential]::new("", $secureToken).Password
$headers = @{ Authorization = "Bearer $token"; Accept = "application/json" }
Invoke-RestMethod -Uri "https://172.16.4.4/api/status/" -Headers $headers
```

This test server has a self-signed certificate, so PowerShell may reject the
connection. Do not disable TLS verification globally. Ask for help setting up
a trusted CA or use the existing Terraform provider's lab-only TLS setting.
Clear `$token` and `$headers` from the session when finished:

```powershell
Remove-Variable token, headers, secureToken -ErrorAction SilentlyContinue
```

Never start with `POST`, `PATCH`, `PUT`, or `DELETE`. First learn `GET`, JSON
fields, pagination, filtering, and status codes. NetBox uses paginated
collection responses; check `count`, `results`, and `next`.

## Stage 4 — Terraform foundations

Terraform compares configuration, state, and the real NetBox API. A plan
explains proposed changes; apply performs them.

Files in this lab:

- `main.tf`: provider requirement and NetBox provider configuration.
- `variables.tf`: NetBox URL and sensitive token input.
- `.terraform.lock.hcl`: selected provider versions and checksums; commit it.
- `.gitignore`: excludes local state, secret variable files, plans, and local
  environment files.
- `STUDY_GUIDE.md`: these lessons.

The provider is `e-breuninger/netbox` `~> 5.8.0`. NetBox reported version
4.7.2, which is newer than the provider's listed tested versions (through
4.6.5); the provider may show a compatibility warning. Terraform in the
workspace was v1.15.9 at the time this guide was prepared. Check versions
before changing either constraint.

Read the `.tf` files, then run only local checks:

```powershell
terraform init
terraform fmt -check
terraform validate
terraform state list
```

`init` downloads providers; `validate` checks configuration structure;
`state list` shows Terraform-managed objects. An empty state list does not
mean NetBox is empty—it only means this Terraform state manages no objects.

Terraform prompts for the required `netbox_token` unless you have supplied it
locally. Never put the token in a `.tf` file. A local `terraform.tfvars` is
ignored by Git, but treat it as a secret.

## Stage 5 — First site (do only when ready)

This is the first lesson that changes NetBox. Confirm the URL, token
permissions, and current inventory first. Use a unique lab name and slug.

Add a resource to a new `site.tf` in the project:

```hcl
resource "netbox_site" "terraform_lab" {
  name        = "Terraform Learning Lab"
  slug        = "terraform-learning-lab"
  status      = "staging"
  description = "Disposable site for a Terraform learning exercise."
}

output "terraform_lab_site_id" {
  value = netbox_site.terraform_lab.id
}
```

<div style="border-left: 5px solid #2f81f7; background-color: #ddf4ff; padding: 0.75em 1em;">
<strong style="color: #0969da;">Blue note — Terraform files and unique names</strong>

Terraform loads and combines every `.tf` file in this folder; it does not run
`main.tf` first or treat another `.tf` file as a separate program. The file
name is for organization.

- Each resource needs a unique Terraform address, such as
  `netbox_site.terraform_lab` and `netbox_site.terraform_lab2`.
- Each output name must also be unique across the folder. Reusing
  `terraform_lab_site_id` in a copied file causes a **Duplicate output
  definition** error.
- NetBox values such as `slug` must be unique too. A second resource should
  use a distinct slug, for example `terraform-learning-lab2`.
- Copying a resource block does not create anything by itself; `terraform
  plan` previews it, and only an approved `terraform apply` makes the change.

For your second-site example, the resource address, output name, and NetBox
slug should each be different. A safe plan should show the first site
unchanged and only the second site as `1 to add`.
</div>

Review the change with Git and validate:

```powershell
git status
git diff
terraform fmt
terraform validate
terraform plan
```

Read the entire plan. It must show only the one intended site being created.
If there are unexpected changes, stop. Only after you understand and approve
the plan, run `terraform apply`, inspect the confirmation prompt, and type
`yes`. Verify the site in the NetBox UI and with:

```powershell
terraform state list
terraform state show netbox_site.terraform_lab
terraform output
```

Then change only the description and plan again. Observe an in-place update.
Do not rename the resource label yet; Terraform treats a label change as a
different address until you learn state moves.

## Stage 6 — VLANs and IPAM

After completing the site exercise, add one VLAN with an unused VLAN ID and a
reference to the managed site's ID. Then add one prefix and one IP address,
following the provider documentation and the NetBox relationships. Use a
private documentation range (for example, a reserved lab range) and check
that each value is unused before planning.

For every object:

1. Inspect existing NetBox data.
2. Change one resource only.
3. Run `terraform fmt`, `terraform validate`, and `terraform plan`.
4. Read whether Terraform creates, updates, replaces, or deletes the object.
5. Apply only the exact intended change.
6. Verify in NetBox and with `terraform state`.

Learn how references create Terraform dependency ordering. Do not use a broad
CIDR or real production address space for an exercise.

## Stage 7 — State, import, and drift

- **State** maps Terraform addresses to remote object IDs; it is not a backup.
- **Import** associates an existing object with a Terraform address; it does
  not write the matching configuration for you.
- **Drift** is a difference between Terraform state/configuration and live
  NetBox data.
- `terraform state rm` removes an address from local state but does not delete
  the NetBox object.
- `terraform destroy` deletes objects managed by the selected state.

Practice import only with a disposable test object. Write matching
configuration first, inspect the exact import address and ID, then plan before
any apply. Never delete or edit a state file to make a plan look clean.

## Stage 8 — Git branches and review

Use a branch for each exercise:

```powershell
git switch -c lesson/site-description
# Make one change
git status
git diff
terraform fmt -check
terraform validate
terraform plan
```

When satisfied, stage selected files, inspect the staged diff, and commit:

```powershell
git add site.tf
git diff --cached
git commit -m "feat: add NetBox learning site"
```

To return to `main`, first make sure your work is committed or safely saved:

```powershell
git switch main
git log --oneline --decorate -5
```

Later, learn merging, conflict resolution, tags, and remote push. Never force
push while learning. A Git commit records configuration; it does not undo an
already-applied NetBox change.

## Stages 9–10 — Reuse and capstone

After the first site, VLAN, prefix, IP, import, and branch exercises, learn:

- Terraform locals, data sources, and reusable modules.
- Separate development/test environments and separate state.
- Remote state, locking, backups, and access controls before team use.
- CI checks such as formatting, validation, and plan review; do not automate
  apply to this live test NetBox until you understand approvals and secrets.

**Capstone:** On a dedicated test instance, use a Git branch to describe one
site, one VLAN, one private prefix, and one address. Review the plan, apply,
verify each relationship in NetBox, then create and review a destroy plan.
Keep users and API tokens outside Terraform configuration.

## End-of-lesson checklist

- I can explain what each changed file does.
- `git diff` contains only the intended change, and no secrets are staged.
- `terraform fmt -check` and `terraform validate` pass.
- I read the complete plan and can describe every action.
- The URL and token target the disposable test instance.
- I can verify the result and know how to remove only the lab objects.
