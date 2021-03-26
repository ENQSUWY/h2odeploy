terraform {
  required_version = ">= 0.13"

  required_providers {
    grafanaauth = {
      source  = "orendain/grafanaauth"
      version = ">= 0.0.3"
    }
  }
}
