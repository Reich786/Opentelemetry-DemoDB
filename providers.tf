terraform {
  required_providers {
    helm = { source = "hashicorp/helm", version = "~> 2.12" }
    kubernetes = { source = "hashicorp/kubernetes", version = "~> 2.17" }
    null = { source = "hashicorp/null", version = "~> 3.2" }
    local = { source = "hashicorp/local", version = "~> 2.1" }
    grafana = { source = "grafana/grafana", version = "~> 2.11" }
  }
  required_version = ">= 1.2.0"
}

provider "kubernetes" {
  config_path = var.kubeconfig_path
}

provider "helm" {
  kubernetes {
    config_path = var.kubeconfig_path
  }
}

# Grafana provider - only used if var.provision_grafana_dashboards = true
provider "grafana" {
  alias = "local"
  url   = var.grafana_url
  auth  = "${var.grafana_admin_user}:${var.grafana_admin_password}"
}
