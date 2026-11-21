output "controller_service_account" {
  value       = { namespace = kubernetes_namespace_v1.this.metadata[0].name, name = var.controller_name }
  description = "Controller service account (controllerServiceAccount of the scale sets)"
}

output "runners_namespace" {
  value       = kubernetes_namespace_v1.runners.metadata[0].name
  description = "Namespace of the runner scale sets"
}
