# OTel Terraform Demo - Quickstart

Prereqs:
- minikube (or a kube cluster)
- kubectl
- helm
- terraform

1) Start cluster (example for minikube):
   minikube start --driver=docker --cpus=4 --memory=7700

2) Init Terraform:
   terraform init

3) First apply (installs helm charts and applies PrometheusRule):
   terraform apply -auto-approve

   - This will install kube-prometheus-stack (monitoring), Jaeger (tracing), Loki/Promtail (logging), and opentelemetry-demo.

4) Port-forward:
   # frontend UI + feature flags + loadgen
   kubectl -n otel-demo port-forward svc/frontend-proxy 8080:8080

   # Prometheus (if needed)
   kubectl -n monitoring port-forward svc/monitoring-kube-prometheus-prometheus 9090:9090

   # Grafana (if using promstack grafana)
   kubectl -n monitoring port-forward svc/monitoring-grafana 3000:80

5) Provision Grafana dashboards:
   - Option A (recommended): port-forward Grafana (step 4) then re-run:
       terraform apply -var='provision_grafana_dashboards=true' -auto-approve
     (This runs the Grafana provider to upload JSON dashboards)
   - Option B: import the dashboard JSON manually in Grafana UI.

6) Validate:
   - Access demo UIs: http://localhost:8080
   - Grafana: http://localhost:3000 (admin/admin123)
   - Prometheus: http://localhost:9090

7) Trigger alerts:
   - Go to Feature Flags UI -> enable e.g., checkout-failure
   - Start Load Generator -> watch Grafana, Prometheus alerts and Alertmanager.
