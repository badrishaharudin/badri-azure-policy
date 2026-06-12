# badri-azure-policy

This repository contains custom Azure Policy definitions.

## Policy created

- `policies/deny-public-ip-on-nic/policy-definition.json`
  - Denies (or audits) network interfaces that have public IPs attached.
- `policies/enforce-vm-sku/policy-definition.json`
  - Allows only approved VM SKUs (sizes) for virtual machines.

## Deploy policy definition (Azure CLI)

```powershell
$subscriptionId = "c3661a0f-624c-40d9-93dd-18cf4a653255"
$definitionName = "deny-public-ip-on-nic"

az account set --subscription $subscriptionId

az policy definition create `
  --name $definitionName `
  --display-name "Deny network interfaces with public IP configurations" `
  --description "Prevents creation or update of NICs with public IPs." `
  --rules "./policies/deny-public-ip-on-nic/policy-definition.json" `
  --mode All
```

## Assign policy (example)

```powershell
$scope = "/subscriptions/c3661a0f-624c-40d9-93dd-18cf4a653255"

az policy assignment create `
  --name "assign-deny-public-ip-on-nic" `
  --display-name "Deny NIC public IP" `
  --policy $definitionName `
  --scope $scope `
  --params '{"effect":{"value":"Deny"}}'
```

## Deploy VM SKU policy definition (Azure CLI)

```powershell
$subscriptionId = "c3661a0f-624c-40d9-93dd-18cf4a653255"
$definitionName = "enforce-vm-sku"

az account set --subscription $subscriptionId

az policy definition create `
  --name $definitionName `
  --display-name "Enforce specific SKU for virtual machines" `
  --description "Allows only approved Azure VM SKUs." `
  --rules "./policies/enforce-vm-sku/policy-definition.json" `
  --mode Indexed
```

## Assign VM SKU policy (example)

```powershell
$scope = "/subscriptions/c3661a0f-624c-40d9-93dd-18cf4a653255"

az policy assignment create `
  --name "assign-enforce-vm-sku" `
  --display-name "Enforce VM SKU" `
  --policy $definitionName `
  --scope $scope `
  --params '{"allowedVmSkus":{"value":["Standard_D2s_v5"]},"effect":{"value":"Deny"}}'
```

## Terraform (VM SKU policy)

Terraform file:

- `terraform/enforce-vm-sku.tf`

Run from the `terraform` folder:

```powershell
cd terraform

terraform init

terraform apply `
  -var "subscription_id=c3661a0f-624c-40d9-93dd-18cf4a653255" `
  -var 'allowed_vm_skus=["Standard_D2s_v5","Standard_D4s_v5"]' `
  -var "effect=Deny"
```

## GitHub ready setup

This repository now includes CI in `.github/workflows/ci.yml`.

CI runs on push and pull request and performs:

- JSON validation for all `policies/**/policy-definition.json` files
- `terraform fmt -check -recursive`
- `terraform init -backend=false`
- `terraform validate`

Recommended local checks before push:

```powershell
terraform -chdir=terraform fmt -check -recursive
terraform -chdir=terraform init -backend=false
terraform -chdir=terraform validate
```
