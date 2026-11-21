resource "kubernetes_namespace_v1" "this" {
  for_each = var.namespaces

  metadata {
    name = each.value
  }
}
