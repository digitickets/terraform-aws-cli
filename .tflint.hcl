#############################################################################################
# In the event that you need to disable a rule within a file, please read about annotations :
# https://github.com/terraform-linters/tflint/blob/master/docs/user-guide/annotations.md
#############################################################################################

config {
  call_module_type = "all"
  force            = false
  format           = "compact"
  ignore_module    = {
    "Invicton-Labs/deepmerge/null" = true
  }
}

tflint {
  required_version = "0.59.1"
}

# Only the AWS plugin is enabled. The Google and Azure plugins are not enabled as we have no current use for them.
# https://github.com/terraform-linters/tflint-ruleset-aws/blob/master/docs/rules/README.md
plugin "aws" {
  enabled    = true
  source     = "github.com/terraform-linters/tflint-ruleset-aws"
  version    = "0.43.0"
  deep_check = true
}

#
# Please check https://github.com/terraform-linters/tflint-ruleset-terraform/tree/main/docs/rules for new rules
#

# Disallow // comments in favor of #
# https://github.com/terraform-linters/tflint-ruleset-terraform/blob/main/docs/rules/terraform_comment_syntax.md
# Checked for changes 2025-10-07
rule "terraform_comment_syntax" {
  enabled = true
}

# Disallow legacy dot index syntax
# https://github.com/terraform-linters/tflint-ruleset-terraform/blob/main/docs/rules/terraform_deprecated_index.md
# Checked for changes 2025-10-07
rule "terraform_deprecated_index" {
  enabled = true
}

# Disallow deprecated (0.11-style) interpolation
# https://github.com/terraform-linters/tflint-ruleset-terraform/blob/main/docs/rules/terraform_deprecated_interpolation.md
# Checked for changes 2025-10-07
rule "terraform_deprecated_interpolation" {
  enabled = true
}

# Disallow deprecated lookup() function with only 2 arguments.
# https://github.com/terraform-linters/tflint-ruleset-terraform/blob/main/docs/rules/terraform_deprecated_lookup.md
# Checked for changes 2025-10-07
rule "terraform_deprecated_lookup" {
  enabled = true
}

# Disallow output declarations without description
# https://github.com/terraform-linters/tflint-ruleset-terraform/blob/main/docs/rules/terraform_documented_outputs.md
# Checked for changes 2025-10-07
rule "terraform_documented_outputs" {
  enabled = true
}

# Disallow variable declarations without description
# https://github.com/terraform-linters/tflint-ruleset-terraform/blob/main/docs/rules/terraform_documented_variables.md
# Checked for changes 2025-10-07
rule "terraform_documented_variables" {
  enabled = true
}

# Disallow comparisons with [] when checking if a collection is empty
# https://github.com/terraform-linters/tflint-ruleset-terraform/blob/main/docs/rules/terraform_empty_list_equality.md
# Checked for changes 2025-10-07
rule "terraform_empty_list_equality" {
  enabled = true
}

# Disallow duplicate keys in a map object
# https://github.com/terraform-linters/tflint-ruleset-terraform/blob/main/docs/rules/terraform_map_duplicate_keys.md
# Checked for changes 2025-10-07
rule "terraform_map_duplicate_keys" {
  enabled = true
}

# Disallow specifying a git or mercurial repository as a module source without pinning to a version
# https://github.com/terraform-linters/tflint-ruleset-terraform/blob/main/docs/rules/terraform_module_pinned_source.md
# Checked for changes 2025-10-07
rule "terraform_module_pinned_source" {
  enabled = true
  style   = "semver"
}

# Require pinned Git-hosted Terraform modules to use shallow cloning
# https://github.com/terraform-linters/tflint-ruleset-terraform/blob/main/docs/rules/terraform_module_shallow_clone.md
# Checked for changes 2025-10-07
rule "terraform_module_shallow_clone" {
  enabled = true
}

# Checks that Terraform modules sourced from a registry specify a version
# https://github.com/terraform-linters/tflint-ruleset-terraform/blob/main/docs/rules/terraform_module_version.md
# Checked for changes 2025-10-07
rule "terraform_module_version" {
  enabled = true
  exact   = true
}

# Enforces naming conventions for resources, data sources, etc
# https://github.com/terraform-linters/tflint-ruleset-terraform/blob/main/docs/rules/terraform_naming_convention.md
# Checked for changes 2025-10-07
rule "terraform_naming_convention" {
  enabled = true
  format  = "snake_case"
}

# Require that all providers have version constraints through required_providers
# https://github.com/terraform-linters/tflint-ruleset-terraform/blob/main/docs/rules/terraform_required_providers.md
# Checked for changes 2025-10-07
rule "terraform_required_providers" {
  enabled = true

  # defaults
  source  = true
  version = true
}

# Disallow terraform declarations without require_version
# https://github.com/terraform-linters/tflint-ruleset-terraform/blob/main/docs/rules/terraform_required_version.md
# Checked for changes 2025-10-07
rule "terraform_required_version" {
  enabled = true
}

# Ensure that a module complies with the Terraform Standard Module Structure
# https://github.com/terraform-linters/tflint-ruleset-terraform/blob/main/docs/rules/terraform_standard_module_structure.md
# Checked for changes 2025-10-07
rule "terraform_standard_module_structure" {
  enabled = true
}

# Disallow variable declarations without type
# https://github.com/terraform-linters/tflint-ruleset-terraform/blob/main/docs/rules/terraform_typed_variables.md
# Checked for changes 2025-10-07
rule "terraform_typed_variables" {
  enabled = true
}

# Disallow variables, data sources, and locals that are declared but never used
# https://github.com/terraform-linters/tflint-ruleset-terraform/blob/main/docs/rules/terraform_unused_declarations.md
# Checked for changes 2025-10-07
rule "terraform_unused_declarations" {
  enabled = true
}

# Check that all required_providers are used in the module
# https://github.com/terraform-linters/tflint-ruleset-terraform/blob/main/docs/rules/terraform_unused_required_providers.md
# Checked for changes 2025-10-07
rule "terraform_unused_required_providers" {
  enabled = true
}

# terraform.workspace should not be used with a "remote" backend with remote execution in Terraform v1.0.x
# https://github.com/terraform-linters/tflint-ruleset-terraform/blob/main/docs/rules/terraform_workspace_remote.md
# Checked for changes 2025-10-07
rule "terraform_workspace_remote" {
  enabled = true
}
