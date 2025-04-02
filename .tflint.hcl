config {
  call_module_type = "all"
  force            = false
  format           = "compact"
}

tflint {
  required_version = ">= 0.56.0"
}

# Only the AWS plugin is enabled. The Google and Azure plugins are not enabled as we have no current use for them.
plugin "aws" {
  enabled    = true
  source     = "github.com/terraform-linters/tflint-ruleset-aws"
  version    = "0.38.0"
  deep_check = true
}

#
# Please check https://github.com/terraform-linters/tflint-ruleset-terraform/tree/v0.5.0/docs/rules for new rules
# (adjust the version accordingly)
#

# Use '#' for comments rather than '//'.
rule "terraform_comment_syntax" {
  enabled = true
}

# List items should be accessed using square brackets
rule "terraform_deprecated_index" {
  enabled = true
}

# Interpolation-only expressions are deprecated in Terraform v0.12.14
rule "terraform_deprecated_interpolation" {
  enabled = true
}

# Lookup with 2 arguments is deprecated
rule "terraform_deprecated_lookup" {
  enabled = true
}

# Outputs require a description
rule "terraform_documented_outputs" {
  enabled = true
}

# Variables require a description
rule "terraform_documented_variables" {
  enabled = true
}

# Comparing a collection with an empty list is invalid. To detect an empty collection, check its length
rule "terraform_empty_list_equality" {
  enabled = true
}

# Disallow specifying a git or mercurial repository as a module source without pinning to a version
rule terraform_module_pinned_source {
  enabled = true
}

# Ensure that all modules sourced from a Terraform Registry specify a version
rule "terraform_module_version" {
  enabled = true
  exact   = false # default
}

# Enforces naming conventions
rule "terraform_naming_convention" {
  enabled = true
  format  = "snake_case"
}

# Require that all providers specify a source and version constraint through required_providers
rule "terraform_required_providers" {
  enabled = true

  # defaults
  source = true
  version = true
}

# Disallow terraform declarations without required_version
rule "terraform_required_version" {
  enabled = true
}

# Ensure that a module complies with the Terraform Standard Module Structure / https://www.terraform.io/docs/modules/index.html#standard-module-structure
rule "terraform_standard_module_structure" {
  enabled = true
}

# Disallow variable declarations without type
rule "terraform_typed_variables" {
  enabled = true
}

# Disallow variables, data sources, and locals that are declared but never used
rule terraform_unused_declarations {
  enabled = true
}

# Check that all required_providers are used in the module
rule terraform_unused_required_providers {
  enabled = true
}
