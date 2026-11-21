# traefik

Traefik ingress controller, deployed twice per cluster (units platform/traefik-public and
platform/traefik-internal), each serving only its own IngressClass – a forged Host header on the public
load balancer can't reach internal services. The internal one is the default class (fail-closed).
RKE2's packaged Traefik is disabled in the cluster unit (tg-env lesson: its chart ignores the service
type and forces its IngressClass to default). CRDs come from RKE2 (rke2-traefik-crd, cluster unit).
Exposure: a Hetzner Cloud load balancer created by the hcloud CCM from the Service annotations
(public, or private network only for the internal one).

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | Traefik chart (traefik.github.io/charts) | `string` | n/a | yes |
| <a name="input_default_class"></a> [default\_class](#input\_default\_class) | Only the internal controller is the default IngressClass (fail-closed) | `bool` | `false` | no |
| <a name="input_ingress_class"></a> [ingress\_class](#input\_ingress\_class) | n/a | `string` | n/a | yes |
| <a name="input_kube_config"></a> [kube\_config](#input\_kube\_config) | Kubeconfig of the cluster (output kube\_config of the cluster unit) | `string` | n/a | yes |
| <a name="input_monitoring_enabled"></a> [monitoring\_enabled](#input\_monitoring\_enabled) | Create ServiceMonitor/PodMonitor objects – needs the Prometheus Operator CRDs (monitoring.coreos.com) in the cluster | `bool` | `false` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | n/a | `string` | n/a | yes |
| <a name="input_proxy_protocol_trusted_ips"></a> [proxy\_protocol\_trusted\_ips](#input\_proxy\_protocol\_trusted\_ips) | Sources allowed to send the PROXY protocol header (private network of the load balancer); empty = off | `list(string)` | `[]` | no |
| <a name="input_release_name"></a> [release\_name](#input\_release\_name) | n/a | `string` | n/a | yes |
| <a name="input_replicas"></a> [replicas](#input\_replicas) | n/a | `number` | `2` | no |
| <a name="input_resources"></a> [resources](#input\_resources) | Kubernetes resources (requests/limits) – set per cluster in stages/infrastructure/kubernetes/<cluster>/resources.tfvars | `any` | <pre>{<br/>  "limits": {<br/>    "memory": "256Mi"<br/>  },<br/>  "requests": {<br/>    "cpu": "50m",<br/>    "memory": "64Mi"<br/>  }<br/>}</pre> | no |
| <a name="input_service_annotations"></a> [service\_annotations](#input\_service\_annotations) | Annotations of the LoadBalancer Service, read by the hcloud CCM (load-balancer.hetzner.cloud/*) | `map(string)` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
