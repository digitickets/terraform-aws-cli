terraform {
  required_version = "~> 1.14" # Updated by inf-base : Fri, 16 Jan 2026 13:36:47 +0000
  required_providers {
    external = {
      source  = "hashicorp/external"
      version = "~> 2" # Updated by inf-base : Fri, 16 Jan 2026 13:36:47 +0000
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2" # Updated by inf-base : Fri, 16 Jan 2026 13:36:47 +0000
    }
  }
}
