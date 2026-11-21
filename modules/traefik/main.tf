# Traefik ingress controller, deployed twice per cluster (units platform/traefik-public and
# platform/traefik-internal), each serving only its own IngressClass – a forged Host header on the public
# load balancer can't reach internal services. The internal one is the default class (fail-closed).
# RKE2's packaged Traefik is disabled in the cluster unit (tg-env lesson: its chart ignores the service
# type and forces its IngressClass to default). CRDs come from RKE2 (rke2-traefik-crd, cluster unit).
# Exposure: a Hetzner Cloud load balancer created by the hcloud CCM from the Service annotations
# (public, or private network only for the internal one).

resource "kubernetes_namespace_v1" "this" {
  metadata {
    name = var.namespace
  }
}

resource "helm_release" "this" {
  name       = var.release_name
  namespace  = kubernetes_namespace_v1.this.metadata[0].name
  repository = "https://traefik.github.io/charts"
  chart      = "traefik"
  version    = var.chart_version
  skip_crds  = true

  values = [yamlencode({
    deployment = {
      replicas = var.replicas
    }
    podDisruptionBudget = { enabled = true, maxUnavailable = 1 }
    affinity = {
      podAntiAffinity = {
        preferredDuringSchedulingIgnoredDuringExecution = [{
          weight = 100
          podAffinityTerm = {
            topologyKey   = "kubernetes.io/hostname"
            labelSelector = { matchLabels = { "app.kubernetes.io/instance" = "${var.release_name}-${var.namespace}" } }
          }
        }]
      }
    }

    ingressClass = {
      enabled        = true
      name           = var.ingress_class
      isDefaultClass = var.default_class
    }

    providers = {
      kubernetesCRD = {
        enabled             = true
        allowCrossNamespace = false
        # Collision-safe names of the generated routers/services (chart value since 3.7.11)
        safeNaming = true
        # Only CRD objects annotated with this class (the public Traefik owns the unannotated ones)
        ingressClass = var.ingress_class
      }
      kubernetesIngress = {
        enabled = true
        # Only Ingresses of this class (not the public ones)
        ingressClass              = var.ingress_class
        allowExternalNameServices = true
        # Ingress status = load balancer address
        publishedService = { enabled = true }
      }
    }

    # Type LoadBalancer is the chart default (service.spec.type; the schema rejects service.type)
    service = {
      annotations = var.service_annotations
    }

    ports = {
      web = {
        transport = { respondingTimeouts = { readTimeout = "1800s" } }
        proxyProtocol = length(var.proxy_protocol_trusted_ips) == 0 ? null : {
          trustedIPs = var.proxy_protocol_trusted_ips
        }
      }
      websecure = {
        transport = { respondingTimeouts = { readTimeout = "1800s" } }
        proxyProtocol = length(var.proxy_protocol_trusted_ips) == 0 ? null : {
          trustedIPs = var.proxy_protocol_trusted_ips
        }
      }
    }

    # JSON on stdout for Alloy (config/alloy/traefik-logs.alloy); access log without headers (cookies,
    # Authorization), client IP = real address thanks to the PROXY protocol
    # (chart 42: top-level log/accessLog – the former logs.general/logs.access fail the schema)
    log = { format = "json" }
    accessLog = {
      enabled = true
      format  = "json"
      headers = { defaultMode = "drop" } # chart default, explicit on purpose
    }

    metrics = {
      prometheus = {
        # Finer latency buckets for the heatmaps of dashboard Traefik (chart default 0.1,0.3,1.2,5)
        buckets = "0.005,0.01,0.025,0.05,0.1,0.25,0.5,1,2.5,5,10,30"
        service = { enabled = true }
        # honorLabels: keep Traefik's own "service" label (otherwise exported_service, because the operator
        # sets service = Kubernetes Service) – same label as on Rancher's k3s Traefik (dashboard Traefik)
        serviceMonitor = { enabled = var.monitoring_enabled, honorLabels = true }
      }
    }

    resources = var.resources
  })]
}
