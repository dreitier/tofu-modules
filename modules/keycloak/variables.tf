variable "kube_config" {
  type        = string
  sensitive   = true
  description = "Kubeconfig of the cluster (output kube_config of the cluster unit)"
}

variable "namespace" {
  type    = string
  default = "keycloak"
}

variable "chart_version" {
  type = string
}

variable "keycloak_version" {
  type = string
}

variable "replicas" {
  type    = number
  default = 2
}

variable "hostname" {
  type        = string
  description = "Public hostname of the IdP"
}

variable "ingress_class" {
  type        = string
  default     = "traefik"
  description = "Public IngressClass (platform/traefik-public)"
}

variable "cluster_issuer" {
  type    = string
  default = "letsencrypt-prod"
}

variable "admin_user" {
  type        = string
  default     = "admin"
  description = "Bootstrap admin of the master realm (first start only)"
}

variable "db_host" {
  type        = string
  default     = "pg-rw.db.svc"
  description = "Read-write service of the CNPG cluster (data/postgresql)"
}

variable "db_name" {
  type    = string
  default = "keycloak"
}

variable "db_user" {
  type    = string
  default = "keycloak"
}

variable "db_kv_name" {
  type    = string
  default = "k8s/prod/postgresql"
}

variable "db_kv_property" {
  type    = string
  default = "user_keycloak_pass"
}

variable "secret_store_name" {
  type    = string
  default = "openbao"
}

variable "admin_kv_name" {
  type    = string
  default = "k8s/prod/keycloak"
}

variable "admin_kv_property" {
  type    = string
  default = "user_admin_pass"
}

variable "resources" {
  type = any
  default = {
    requests = { cpu = "250m", memory = "768Mi" }
    limits   = { memory = "1536Mi" }
  }
}

variable "extra_providers" {
  type = list(object({
    name   = string # file name without .jar
    url    = string
    sha256 = string
  }))
  default     = []
  description = "Keycloak extensions (provider JARs), pinned by checksum"
}

variable "init_image" {
  type = string
  # renovate: datasource=docker depName=alpine
  default     = "alpine:3.24"
  description = "Image of the init container that downloads the provider JARs (wget, sha256sum)"
}

variable "init_resources" {
  type        = any
  description = "Init container that downloads the extra providers – every container needs requests + a memory limit (Kyverno require-requests-limits); sized from the 7-day maxima in Prometheus (2026-11-18)"
  default     = { requests = { cpu = "10m", memory = "16Mi" }, limits = { memory = "64Mi" } }
}
