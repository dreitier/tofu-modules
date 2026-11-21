variable "kube_config" {
  type        = string
  sensitive   = true
  description = "Kubeconfig of the cluster (output kube_config of the cluster unit)"
}

variable "chart_version" {
  type        = string
  description = "dependency-track chart version (https://dependencytrack.github.io/helm-charts; 2.9.x = DT 5.2.x)"
}

variable "namespace" {
  type    = string
  default = "dependency-track"
}

variable "internal_hostname" {
  type        = string
  description = "UI + full API, VPN only, e.g. dependency-track.intern.dreitier.com"
}

variable "public_hostname" {
  type        = string
  description = "BOM upload API only, public, e.g. dependency-track.dreitier.com (A/AAAA → public LB in inwx/dns)"
}

variable "internal_ingress_class" {
  type    = string
  default = "traefik-internal"
}

variable "public_ingress_class" {
  type        = string
  default     = "traefik"
  description = "Public IngressClass (platform/traefik-public)"
}

variable "cluster_issuer" {
  type    = string
  default = "letsencrypt-prod"
}

variable "keycloak_url" {
  type        = string
  description = "Keycloak base URL, e.g. https://idp.dreitier.com"
}

variable "keycloak_realm" {
  type    = string
  default = "dreitier"
}

variable "oidc_client_id" {
  type        = string
  default     = "dependency-track"
  description = "Public Keycloak client (config/keycloak) – used by the frontend and to validate ID tokens"
}

variable "db_host" {
  type        = string
  default     = "pg-rw.db.svc"
  description = "Read-write service of the CNPG cluster (data/postgresql)"
}

variable "db_name" {
  type    = string
  default = "dtrack"
}

variable "db_user" {
  type    = string
  default = "dtrack"
}

variable "db_kv_name" {
  type        = string
  default     = "k8s/prod/postgresql-dtrack"
  description = "OpenBao entry with the role password (property user_<db_user>_pass, config/openbao-base)"
}

variable "kek_kv_name" {
  type        = string
  default     = "k8s/prod/dependency-track"
  description = "OpenBao entry with the KEK (property kek, scripts/dependency-track-kek.sh)"
}

variable "secret_store_name" {
  type    = string
  default = "openbao"
}

variable "storage_class" {
  type    = string
  default = "hcloud-volumes"
}

variable "storage_size" {
  type    = string
  default = "10Gi"
}

variable "resources" {
  type = object({
    api_server = optional(any, { requests = { cpu = "250m", memory = "1536Mi" }, limits = { memory = "2Gi" } })
    frontend   = optional(any, { requests = { cpu = "20m", memory = "64Mi" }, limits = { memory = "128Mi" } })
  })
  description = "Kubernetes resources – set per cluster in stages/infrastructure/kubernetes/<cluster>/resources.tfvars (key dependency_track)"
  default     = {}
}

variable "monitoring_enabled" {
  type        = bool
  description = "ServiceMonitor of the api-server – needs the Prometheus Operator CRDs (monitoring.coreos.com)"
  default     = false
}
