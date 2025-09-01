# Create namespaces via kubernetes manifest (Helm charts also create namespaces but we create them proactively)
resource "kubernetes_namespace" "demo" {
  metadata {
    name = var.namespace_demo
  }
}

resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = var.namespace_monitoring
  }
}

resource "kubernetes_namespace" "logging" {
  metadata {
    name = var.namespace_logging
  }
}

resource "kubernetes_namespace" "tracing" {
  metadata {
    name = var.namespace_tracing
  }
}

# -----------------------
# Install kube-prometheus-stack (Prometheus + Alertmanager + Grafana)
# -----------------------
resource "helm_release" "promstack" {
  name       = "monitoring"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  create_namespace = false

  # Keep values minimal: allow chart defaults
  values = [
    <<-EOF
    grafana:
      adminPassword: "${var.grafana_admin_password}"
      service:
        type: ClusterIP
    prometheus:
      prometheusSpec:
        serviceMonitorSelectorNilUsesHelmValues: false
    EOF
  ]
  depends_on = [kubernetes_namespace.monitoring]
}

# -----------------------
# Install Grafana (optional - note: kube-prometheus installs a Grafana, but this is explicit if you prefer)
# (We use the Grafana installed by kube-prometheus-stack for dashboards by default)
# -----------------------
# If you want separate Grafana, add helm_release for grafana here. For this setup we'll use the Grafana from promstack.

# -----------------------
# Install Jaeger (tracing)
# -----------------------
resource "helm_release" "jaeger" {
  name       = "jaeger"
  repository = "https://jaegertracing.github.io/helm-charts"
  chart      = "jaeger"
  namespace  = kubernetes_namespace.tracing.metadata[0].name
  create_namespace = false

  values = [
    <<-EOF
    allInOne:
      enabled: true
    agent:
      enabled: false
    provisionDataStore:
      cassandra: false
    storage:
      type: memory
    EOF
  ]
  depends_on = [kubernetes_namespace.tracing]
}

# -----------------------
# Install Loki + Promtail (logging)
# -----------------------
resource "helm_release" "loki" {
  name       = "loki"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki"
  namespace  = kubernetes_namespace.logging.metadata[0].name
  create_namespace = false

  values = [
    <<-EOF
    persistence:
      enabled: false
    EOF
  ]
  depends_on = [kubernetes_namespace.logging]
}

resource "helm_release" "promtail" {
  name       = "promtail"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "promtail"
  namespace  = kubernetes_namespace.logging.metadata[0].name
  create_namespace = false

  values = [
    <<-EOF
    config:
      clients:
        - url: http://loki.${var.namespace_logging}.svc:3100/loki/api/v1/push
    EOF
  ]
  depends_on = [helm_release.loki]
}

# -----------------------
# Install OpenTelemetry Demo
# -----------------------
resource "helm_release" "otel_demo" {
  name       = "otel-demo"
  repository = "https://open-telemetry.github.io/opentelemetry-helm-charts"
  chart      = "opentelemetry-demo"
  namespace  = kubernetes_namespace.demo.metadata[0].name
  create_namespace = false

  # if you want to adjust feature flags defaults, provide custom values.yaml here.
  # values = [file("${path.module}/demo-values.yaml")]
  depends_on = [kubernetes_namespace.demo]
}

# -----------------------
# Apply Prometheus alert rules via kubectl (null_resource)
# -----------------------
resource "null_resource" "apply_prometheus_rules" {
  # run after promstack and otel demo
  depends_on = [
    helm_release.promstack,
    helm_release.otel_demo
  ]

  provisioner "local-exec" {
    command = "kubectl apply -f ${path.module}/alerts/otel-demo-prometheusrules.yaml"
  }
}
