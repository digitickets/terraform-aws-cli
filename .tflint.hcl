config {
  module = true
  force  = false
}

// Only the AWS plugin is enabled. The Google and Azure plugins are not enabled as we have no current use for them.
plugin "aws" {
  enabled    = true
  source     = "github.com/terraform-linters/tflint-ruleset-aws"
  version    = "0.21.2"
  deep_check = true
}

rule "terraform_naming_convention" {
  enabled = true
}

rule "terraform_deprecated_interpolation" {
  enabled = true
}

rule "terraform_documented_outputs" {
  enabled = true
}

rule "terraform_documented_variables" {
  enabled = true
}

rule "terraform_module_pinned_source" {
  enabled = true
}
