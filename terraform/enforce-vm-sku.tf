terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

locals {
  vm_sku_policy = jsondecode(file("${path.module}/../policies/enforce-vm-sku/policy-definition.json"))
}

variable "subscription_id" {
  description = "Target Azure subscription ID."
  type        = string
  default     = "c3661a0f-624c-40d9-93dd-18cf4a653255"
}

variable "policy_definition_name" {
  description = "Name of the custom policy definition."
  type        = string
  default     = "enforce-vm-sku"
}

variable "policy_assignment_name" {
  description = "Name of the policy assignment."
  type        = string
  default     = "assign-enforce-vm-sku"
}

variable "allowed_vm_skus" {
  description = "VM SKUs allowed by this policy assignment."
  type        = list(string)
  default     = ["Standard_D2s_v5"]
}

variable "effect" {
  description = "Policy effect for non-compliant resources."
  type        = string
  default     = "Deny"

  validation {
    condition     = contains(["Deny", "Audit", "Disabled"], var.effect)
    error_message = "effect must be one of: Deny, Audit, Disabled."
  }
}

resource "azurerm_policy_definition" "enforce_vm_sku" {
  name         = var.policy_definition_name
  policy_type  = local.vm_sku_policy.properties.policyType
  mode         = local.vm_sku_policy.properties.mode
  display_name = local.vm_sku_policy.properties.displayName
  description  = local.vm_sku_policy.properties.description
  metadata     = jsonencode(local.vm_sku_policy.properties.metadata)
  parameters   = jsonencode(local.vm_sku_policy.properties.parameters)
  policy_rule  = jsonencode(local.vm_sku_policy.properties.policyRule)
}

resource "azurerm_subscription_policy_assignment" "enforce_vm_sku" {
  name                 = var.policy_assignment_name
  subscription_id      = "/subscriptions/${var.subscription_id}"
  policy_definition_id = azurerm_policy_definition.enforce_vm_sku.id
  display_name         = "Enforce VM SKU"
  description          = "Allows only approved VM SKUs."

  parameters = jsonencode({
    allowedVmSkus = {
      value = var.allowed_vm_skus
    }
    effect = {
      value = var.effect
    }
  })
}
