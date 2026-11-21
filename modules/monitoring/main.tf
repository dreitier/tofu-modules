# Monitoring stack of a cluster (docs/monitoring.md in basement): metrics, logs and alerts, all internal (VPN).
#   prometheus.tf  kube-prometheus-stack (Prometheus, Alertmanager → mail via the mail relay, operator,
#                  kube-state-metrics, node-exporter), blackbox exporter, own alert rules
#   grafana.tf     Grafana, login via Keycloak; dashboards.tf provisions the own dashboards
#   loki.tf        Loki single binary, chunks/index in S3-compatible object storage
#   alloy.tf       Grafana k8s-monitoring (Alloy): pod logs, node journal, events → Loki; etcd metrics
#   secrets.tf     credentials from OpenBao (ClusterSecretStore) – nothing secret in Helm values or the state
# The resources live in the files named above; this file only describes the module.
