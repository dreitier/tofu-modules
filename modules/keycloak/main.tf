# Keycloak (identity broker for Entra ID; OIDC provider of OpenBao, NetBird and the apps).
# Public: NetBird clients and the dashboard log in from the Internet → public IngressClass.
# Not the Bitnami chart (tg-env lesson: Bitnami images are frozen) – codecentric keycloakx with the
# upstream image, database on the CNPG cluster (data/postgresql), admin password and DB password from
# OpenBao via ExternalSecrets.
# Upstream image without a custom build: `kc.sh start` builds at startup (KC_DB etc. are build options) –
# slower start, no image of our own. Bootstrap admin (KC_BOOTSTRAP_ADMIN_*) is only applied on the very
# first start against an empty database; afterwards config/keycloak manages users.

resource "kubernetes_namespace_v1" "this" {
  metadata {
    name = var.namespace
  }
}

resource "kubernetes_manifest" "admin_secret" {
  manifest = {
    apiVersion = "external-secrets.io/v1"
    kind       = "ExternalSecret"
    metadata   = { name = "keycloak-admin", namespace = kubernetes_namespace_v1.this.metadata[0].name }
    spec = {
      secretStoreRef = { kind = "ClusterSecretStore", name = var.secret_store_name }
      target         = { name = "keycloak-admin", creationPolicy = "Owner" }
      data = [{
        secretKey = "password"
        remoteRef = { key = var.admin_kv_name, property = var.admin_kv_property }
      }]
    }
  }
}

# Password of the database role (data/postgresql creates the role with the same OpenBao entry)
resource "kubernetes_manifest" "db_secret" {
  manifest = {
    apiVersion = "external-secrets.io/v1"
    kind       = "ExternalSecret"
    metadata   = { name = "keycloak-db", namespace = kubernetes_namespace_v1.this.metadata[0].name }
    spec = {
      secretStoreRef = { kind = "ClusterSecretStore", name = var.secret_store_name }
      target         = { name = "keycloak-db", creationPolicy = "Owner" }
      data = [{
        secretKey = "password"
        remoteRef = { key = var.db_kv_name, property = var.db_kv_property }
      }]
    }
  }
}

resource "helm_release" "this" {
  name       = "keycloak"
  namespace  = kubernetes_namespace_v1.this.metadata[0].name
  repository = "https://codecentric.github.io/helm-charts"
  chart      = "keycloakx"
  version    = var.chart_version

  values = [yamlencode({
    image    = { repository = "quay.io/keycloak/keycloak", tag = var.keycloak_version }
    replicas = var.replicas
    command  = ["/opt/keycloak/bin/kc.sh", "start"]

    # Served at / (the chart's default is /auth)
    http = { relativePath = "/" }

    # TLS ends at Traefik; Keycloak trusts its X-Forwarded-* headers
    proxy = { enabled = true, mode = "xforwarded", http = { enabled = true } }

    database = {
      vendor            = "postgres"
      hostname          = var.db_host
      port              = 5432
      database          = var.db_name
      username          = var.db_user
      existingSecret    = "keycloak-db"
      existingSecretKey = "password"
    }

    # The chart renders KC_HEALTH_ENABLED/KC_METRICS_ENABLED from these (probes need health on :9000).
    # Never repeat them in extraEnv: duplicate env names break the StatefulSet patch, and removing a
    # duplicate later deletes both entries (strategic merge by name).
    health  = { enabled = true }
    metrics = { enabled = true }

    # Cluster discovery: Keycloak 26 default (jdbc-ping via the database) – no headless DNS needed
    extraEnv = yamlencode([
      { name = "KC_HOSTNAME", value = "https://${var.hostname}" },
      { name = "KC_BOOTSTRAP_ADMIN_USERNAME", value = var.admin_user },
      { name = "KC_BOOTSTRAP_ADMIN_PASSWORD", valueFrom = { secretKeyRef = { name = "keycloak-admin", key = "password" } } },
      # Mitigation for the Base64 intrinsic JIT bug (java2shell). JAVA_OPTS_APPEND, not JAVA_OPTS:
      # kc.sh replaces its default JVM options (heap sizing, --add-opens) when JAVA_OPTS is set.
      { name = "JAVA_OPTS_APPEND", value = "-XX:-UseBASE64Intrinsics" },
      # JSON logs on stdout (Quarkus default JSON format), parsed by Alloy (basement config/alloy/workload-logs.alloy)
      { name = "KC_LOG_CONSOLE_OUTPUT", value = "json" },
    ])

    # Extensions (var.extra_providers): downloaded by an init container into an emptyDir at
    # /opt/keycloak/providers, checksum-verified; `kc.sh start` builds them in
    extraInitContainers = length(var.extra_providers) == 0 ? "" : yamlencode([{
      name  = "providers"
      image = var.init_image
      command = ["sh", "-ec", join("\n", concat(
        [for p in var.extra_providers : "wget -q -O /providers/${p.name}.jar '${p.url}'"],
        [for p in var.extra_providers : "echo '${p.sha256}  /providers/${p.name}.jar' | sha256sum -c -"],
      ))]
      volumeMounts = [{ name = "providers", mountPath = "/providers" }]
      resources    = var.init_resources
    }])
    extraVolumes      = length(var.extra_providers) == 0 ? "" : yamlencode([{ name = "providers", emptyDir = {} }])
    extraVolumeMounts = length(var.extra_providers) == 0 ? "" : yamlencode([{ name = "providers", mountPath = "/opt/keycloak/providers" }])

    ingress = {
      enabled          = true
      ingressClassName = var.ingress_class
      annotations      = { "cert-manager.io/cluster-issuer" = var.cluster_issuer }
      rules            = [{ host = var.hostname, paths = [{ path = "/", pathType = "Prefix" }] }]
      tls              = [{ hosts = [var.hostname], secretName = "keycloak-tls" }]
    }
    resources = var.resources
  })]

  depends_on = [kubernetes_manifest.admin_secret, kubernetes_manifest.db_secret]
}
