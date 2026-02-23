terraform {
  required_version = "~> 1.14" # Updated by inf-base : Mon, 23 Feb 2026 12:13:47 +0000
  required_providers {
    external = {
      source  = "hashicorp/external"
      version = "~> 2" # Updated by inf-base : Mon, 23 Feb 2026 12:20:22 +0000
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2" # Updated by inf-base : Mon, 23 Feb 2026 12:20:22 +0000
    }
  }
}
