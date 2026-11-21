variable "kube_config" {
  type        = string
  sensitive   = true
  description = "Kubeconfig of the cluster (output kube_config of the cluster unit)"
}

variable "namespace" {
  type = string
}

variable "release_name" {
  type = string
}

variable "chart_version" {
  type        = string
  description = "Traefik chart (traefik.github.io/charts)"
}

variable "ingress_class" {
  type = string
}

variable "default_class" {
  type        = bool
  default     = false
  description = "Only the internal controller is the default IngressClass (fail-closed)"
}

variable "service_annotations" {
  type        = map(string)
  description = "Annotations of the LoadBalancer Service, read by the hcloud CCM (load-balancer.hetzner.cloud/*)"
}

variable "proxy_protocol_trusted_ips" {
  type        = list(string)
  default     = []
  description = "Sources allowed to send the PROXY protocol header (private network of the load balancer); empty = off"
}

variable "replicas" {
  type    = number
  default = 2
}

variable "resources" {
  type        = any
  description = "Kubernetes resources (requests/limits) – set per cluster in stages/infrastructure/kubernetes/<cluster>/resources.tfvars"
  default = {
    requests = { cpu = "50m", memory = "64Mi" }
    limits   = { memory = "256Mi" }
  }
}

variable "monitoring_enabled" {
  type        = bool
  description = "Create ServiceMonitor/PodMonitor objects – needs the Prometheus Operator CRDs (monitoring.coreos.com) in the cluster"
  default     = false
}
