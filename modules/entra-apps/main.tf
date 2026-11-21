# Enterprise applications / app registrations of the consumers of Entra ID. First one: Keycloak as
# identity broker. TODO AWS IAM Identity Center (SAML + SCIM), GitHub (SAML, needs Enterprise Cloud).
#
# Keycloak broker: OIDC web app with redirect URI https://<idp>/realms/<realm>/broker/entra/endpoint,
# groups claim (security groups) in ID tokens. Credential: a certificate (public key only, uploaded here)
# instead of a client secret – azuread_application_password would put the secret into the state.

resource "azuread_application" "keycloak" {
  count = var.keycloak_enabled ? 1 : 0

  display_name     = var.keycloak_app_name
  sign_in_audience = "AzureADMyOrg"

  group_membership_claims = ["SecurityGroup"]

  web {
    redirect_uris = [var.keycloak_broker_redirect_uri]
  }

  optional_claims {
    id_token {
      name = "groups"
    }
    # Users without a mailbox have no email claim otherwise
    id_token {
      name = "email"
    }
  }
}

resource "azuread_service_principal" "keycloak" {
  count = var.keycloak_enabled ? 1 : 0

  client_id = azuread_application.keycloak[0].client_id
}

# Keycloak signs the client assertion (private_key_jwt) with the realm's active RS256 key; its
# certificate (public) is read from the realm JWKS. Only once the realm exists (keycloak_realm_jwks_url).
# After a realm key rotation: apply again (the certificate value changes → replaced).
data "http" "keycloak_jwks" {
  count = var.keycloak_enabled && var.keycloak_realm_jwks_url != null ? 1 : 0
  url   = var.keycloak_realm_jwks_url

  lifecycle {
    postcondition {
      condition     = self.status_code == 200
      error_message = "Realm JWKS not readable (HTTP ${self.status_code}) – does the realm exist yet?"
    }
  }
}

locals {
  keycloak_jwks_cert = try(one([
    for k in jsondecode(data.http.keycloak_jwks[0].response_body).keys : k.x5c[0]
    if k.alg == "RS256" && k.use == "sig"
  ]), null)
  keycloak_broker_certificate_pem = coalesce(
    var.keycloak_broker_certificate_pem,
    local.keycloak_jwks_cert == null ? null : "-----BEGIN CERTIFICATE-----\n${local.keycloak_jwks_cert}\n-----END CERTIFICATE-----\n",
    "none",
  )
}

resource "azuread_application_certificate" "keycloak" {
  count = var.keycloak_enabled && (var.keycloak_broker_certificate_pem != null || var.keycloak_realm_jwks_url != null) ? 1 : 0

  application_id = azuread_application.keycloak[0].id
  type           = "AsymmetricX509Cert"
  value          = local.keycloak_broker_certificate_pem
  end_date       = var.keycloak_broker_certificate_end_date
}
