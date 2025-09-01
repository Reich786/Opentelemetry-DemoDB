variable "kubeconfig_path" {
  description = "Kubeconfig path"
  type        = string
  default     = "~/.kube/config"
}

variable "namespace_demo" {
  type    = string
  default = "otel-demo"
}

variable "namespace_monitoring" {
  type    = string
  default = "monitoring"
}

variable "namespace_logging" {
  type    = string
  default = "logging"
}

variable "namespace_tracing" {
  type    = string
  default = "tracing"
}

variable "grafana_admin_user" {
  type    = string
  default = "admin"
}

variable "grafana_admin_password" {
  type    = string
  default = "admin123"
}

variable "grafana_url" {
  type    = string
  default = "http://localhost:3000" # change if different
}

variable "provision_grafana_dashboards" {
  description = "Set to true after Grafana is reachable (eg port-forward) to provision dashboards"
  type        = bool
  default     = false
}
