variable "kube_config" {
  type        = string
  sensitive   = true
  description = "Kubeconfig of the cluster (output kube_config of the cluster unit)"
}

variable "chart_version" {
  type        = string
  description = "cert-manager chart version (keep the deployed one for the import, upgrade separately)"
}

variable "namespace" {
  type    = string
  default = "cert-manager"
}

variable "aws_region" {
  type        = string
  description = "AWS_REGION of the controller (STS/Route53), from config/globals/aws.tfvars"
}

variable "route53_role_arn" {
  type        = string
  default     = null
  description = "IRSA role for DNS-01 (aws/irsa-<cluster>, role <cluster>-cert-manager); null = no Route53 access"
}

variable "resources" {
  type        = any
  description = "Kubernetes resources (requests/limits) – set per cluster in stages/infrastructure/kubernetes/<cluster>/resources.tfvars (keys controller, webhook, cainjector)"
  default = {
    controller = { limits = { memory = "256Mi" } }
    webhook    = { limits = { memory = "128Mi" } }
    cainjector = { limits = { memory = "256Mi" } }
  }
}

variable "monitoring_enabled" {
  type        = bool
  description = "Create ServiceMonitor/PodMonitor objects – needs the Prometheus Operator CRDs (monitoring.coreos.com) in the cluster"
  default     = false
}
