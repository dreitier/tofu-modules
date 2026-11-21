# SAML clients (service providers without OIDC, e.g. AWS IAM Identity Center). The SP gets the realm's IdP
# metadata (https://<keycloak>/realms/<realm>/protocol/saml/descriptor) once by hand. No secrets: assertions
# are signed with the realm key. Access restriction like the OIDC clients (access.tf, access_groups).

resource "keycloak_saml_client" "this" {
  for_each = var.saml_clients

  realm_id  = keycloak_realm.this.id
  client_id = each.value.entity_id # = the SP's issuer / audience
  name      = each.value.name
  enabled   = true

  base_url                    = each.value.base_url
  valid_redirect_uris         = distinct(concat([each.value.acs_url], each.value.extra_acs_urls))
  assertion_consumer_post_url = each.value.acs_url

  name_id_format       = each.value.name_id_format
  force_name_id_format = true

  sign_documents            = true
  sign_assertions           = true
  signature_algorithm       = "RSA_SHA256"
  encrypt_assertions        = false
  client_signature_required = each.value.client_signature_required
  force_post_binding        = true
  front_channel_logout      = false

  # No role list in the assertion
  full_scope_allowed = false
}

# Keycloak's default SAML scopes (role_list) would add a "Role" attribute – the SPs only need the NameID
resource "keycloak_saml_client_default_scopes" "this" {
  for_each = var.saml_clients

  realm_id       = keycloak_realm.this.id
  client_id      = keycloak_saml_client.this[each.key].id
  default_scopes = []
}

check "client_keys" {
  assert {
    condition     = length(setintersection(keys(var.clients), keys(var.saml_clients))) == 0
    error_message = "saml_clients and clients share keys – the restricted-access roles would collide."
  }
}
