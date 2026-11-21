variable "kube_config" {
  type        = string
  sensitive   = true
  description = "Kubeconfig of the cluster (output kube_config of the cluster unit)"
}

variable "name" {
  type    = string
  default = "openbao"
}

variable "openbao_server" {
  type        = string
  description = "OpenBao address as seen from the cluster (in-cluster service URL)"
}

variable "ca_bundle_pem" {
  type        = string
  default     = null
  description = "CA of the OpenBao listener if it is not publicly trusted"
}

variable "kv_mount" {
  type    = string
  default = "infra"
}

variable "auth_mount" {
  type    = string
  default = "kubernetes"
}

variable "auth_role" {
  type        = string
  default     = "external-secrets"
  description = "Role of the kubernetes auth method (config/openbao)"
}

variable "service_account" {
  type = object({
    name      = string
    namespace = string
  })
  default = {
    name      = "external-secrets"
    namespace = "external-secrets"
  }
}
