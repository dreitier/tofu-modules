# mail-relay

SMTP relay for the cluster (Alertmanager, Grafana, Psono, …): Postfix (dreitier/helm-charts postfix)
without authentication on a ClusterIP service, forwarding to Exchange Online.
Upstream: the tenant's MX host on port 25 with STARTTLS and no SASL – Exchange accepts the mail through an
inbound connector bound to the cluster's egress IP (the gateway, all node traffic is NATed through it).
Basic SMTP AUTH (smtp.office365.com:587) is not used: Microsoft disables it by default end of 2026.
Manual parts (docs/mail-relay.md): the Exchange connector, the gateway IP in the SPF record.

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_allowed_senders"></a> [allowed\_senders](#input\_allowed\_senders) | Envelope sender (MAIL FROM) and header From addresses the relay accepts; everything else is rejected.<br/>Exchange treats the relay's mail as internal (connector TreatMessagesAsInternal), so without this list any<br/>pod could send internal mail as any @domain address. [] = no restriction. | `list(string)` | `[]` | no |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | n/a | `string` | n/a | yes |
| <a name="input_kube_config"></a> [kube\_config](#input\_kube\_config) | n/a | `string` | n/a | yes |
| <a name="input_myhostname"></a> [myhostname](#input\_myhostname) | HELO name / Received header of the relay | `string` | n/a | yes |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | n/a | `string` | `"mail-relay"` | no |
| <a name="input_relay_host"></a> [relay\_host](#input\_relay\_host) | MX host of the Microsoft 365 tenant (dig MX <domain>), e.g. dreitier-com.mail.protection.outlook.com | `string` | n/a | yes |
| <a name="input_relay_networks"></a> [relay\_networks](#input\_relay\_networks) | Clients allowed to relay: the RKE2 pod network (ClusterIP service → connections come from pods) | `list(string)` | <pre>[<br/>  "127.0.0.0/8",<br/>  "10.42.0.0/16"<br/>]</pre> | no |
| <a name="input_release_name"></a> [release\_name](#input\_release\_name) | n/a | `string` | `"mail-relay"` | no |
| <a name="input_resources"></a> [resources](#input\_resources) | n/a | `any` | <pre>{<br/>  "limits": {<br/>    "memory": "128Mi"<br/>  },<br/>  "requests": {<br/>    "cpu": "10m",<br/>    "memory": "32Mi"<br/>  }<br/>}</pre> | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_smtp_host"></a> [smtp\_host](#output\_smtp\_host) | In-cluster SMTP host (port 25, no auth, no TLS) |
<!-- END_TF_DOCS -->
