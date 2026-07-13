# terraform-cloudrun-v2

Terraform module for a multi-region [Google Cloud Run v2 Service](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_run_v2_service) behind a [serverless Network Endpoint Group (NEG)](https://cloud.google.com/load-balancing/docs/negs/serverless-neg-concepts).

Variables support GPUs, GCS mounts, multi-containers, service ingress, custom audiences, request timeout, max concurrency, labels, and startup/liveness HTTP probes.

## Direct VPC egress

Set `vpc_direct_egress` to `PRIVATE_RANGES_ONLY` or `ALL_TRAFFIC`. The module retains its compatible `default` network and subnet defaults. To configure only one interface field, set the other explicitly to `null`; Cloud Run then infers the omitted network or same-named regional subnet as described in [Direct VPC configuration](https://cloud.google.com/run/docs/configuring/vpc-direct-vpc). Enabling egress with both fields set to `null` is rejected during planning. A fully qualified subnet must embed the same region as each Cloud Run service. For a multi-region service, use network-only inference with a same-named subnet in every region or use separate module instances so each region receives an explicit subnet.

Direct VPC is the outbound VPC leg for Cloud Run services; it does not provide Direct VPC ingress to a service. Requests can still enter through the service's configured Cloud Run ingress, but a service reaching a VM or other private destination uses Direct VPC egress.

This module configures the Cloud Run attachment, but the caller owns its network prerequisites. Use an IPv4 subnet of `/26` or larger from RFC 1918, RFC 6598 (`100.64.0.0/10`), or Class E (`240.0.0.0/4`), and retain Google Cloud's default network MTU of 1460. The Cloud Run service agent normally receives `roles/run.serviceAgent` in its service project. For Shared VPC, grant that service-project agent either `roles/compute.networkUser` on the host project, or `roles/compute.networkViewer` on the host project plus `roles/compute.networkUser` on the selected subnet. Authorize destination ingress from the entire subnet CIDR rather than ephemeral instance addresses; Cloud Run network tags and service identities cannot identify the source of an ingress firewall rule.

Cloud Run reserves addresses in `/28` blocks during scale-up and uses roughly twice the steady-state instance count. Leave additional capacity for overlapping revisions, and wait 1–2 hours after disconnecting Cloud Run before deleting a subnet. Applications must tolerate occasional connection resets during network maintenance. If all traffic exits through Cloud NAT, account for the documented cold-start delay or evaluate a Serverless VPC Access connector when startup latency is more important than connector cost.

## Load-balancer-only endpoints

For a service protected by an external Application Load Balancer and Cloud Armor, set `ingress = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"`, `default_uri_disabled = true`, and `launch_stage = "BETA"`. Disabling the default `run.app` URL prevents callers from bypassing the load balancer policy. This Cloud Run feature is currently Preview. It also prevents products that invoke the default URL directly, including Cloud Scheduler, Cloud Tasks, Eventarc, Pub/Sub, Workflows, and uptime checks, from reaching the service; configure another supported endpoint before enabling it.

## HTTP startup probes

The legacy `startup_probe = "/startup"` container attribute remains supported. Use `startup_probe_config` when timing controls are required:

```hcl
containers = [{
  image = "us-docker.pkg.dev/example/project/app:latest"
  name  = "app"
  port  = 8080
  startup_probe_config = {
    path                  = "/startup"
    initial_delay_seconds = 10
    timeout_seconds       = 2
    period_seconds        = 5
    failure_threshold     = 12
  }
}]
```

Probe settings are validated against [Cloud Run's startup-probe limits](https://cloud.google.com/run/docs/configuring/healthchecks). If both forms are set, `startup_probe_config` takes precedence. For Direct VPC readiness, the endpoint must verify a connection to an egress dependency before reporting success; either the endpoint can retry internally or it can return failure so Cloud Run retries it within the configured period and threshold window. A generic process-only endpoint does not cover the documented startup connection delay. Probe paths are part of the service's HTTP surface and are reachable by clients allowed through its ingress and authentication policy, so keep responses non-sensitive and make the handler free of state-changing side effects.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_google"></a> [google](#requirement\_google) | ~> 7.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | ~> 7.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [google_cloud_run_v2_service.cloudrun](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_run_v2_service) | resource |
| [google_cloud_run_v2_service_iam_member.invoker](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_run_v2_service_iam_member) | resource |
| [google_compute_backend_service.backend](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_backend_service) | resource |
| [google_compute_region_network_endpoint_group.neg](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_region_network_endpoint_group) | resource |
| [google_service_account.service_account](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/service_account) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_addl_env_vars"></a> [addl\_env\_vars](#input\_addl\_env\_vars) | Additional environment variables to set in containers | <pre>list(object({<br/>    name  = string<br/>    value = string<br/>  }))</pre> | `[]` | no |
| <a name="input_containers"></a> [containers](#input\_containers) | List of container configurations to run in the service. At least one container needs a port. startup\_probe\_config takes precedence over the legacy startup\_probe path when both are set. | <pre>list(object({<br/>    image          = string<br/>    name           = string<br/>    command        = optional(list(string), null)<br/>    args           = optional(list(string), null)<br/>    port           = optional(number, 0)<br/>    memory         = optional(string, "512Mi")<br/>    cpu            = optional(string, "1000m")<br/>    liveness_probe = optional(string, "")<br/>    startup_probe  = optional(string, "")<br/>    startup_probe_config = optional(object({<br/>      path                  = string<br/>      initial_delay_seconds = optional(number, 0)<br/>      timeout_seconds       = optional(number, 1)<br/>      period_seconds        = optional(number, 10)<br/>      failure_threshold     = optional(number, 3)<br/>    }), null)<br/>    gpus = optional(string, "")<br/>    volume_mounts = optional(list(object({<br/>      name       = string<br/>      mount_path = string<br/>    })), [])<br/>  }))</pre> | n/a | yes |
| <a name="input_custom_audiences"></a> [custom\_audiences](#input\_custom\_audiences) | Custom audiences accepted by each Cloud Run service. | `list(string)` | `[]` | no |
| <a name="input_default_uri_disabled"></a> [default\_uri\_disabled](#input\_default\_uri\_disabled) | Whether to disable the service's default run.app URL. This preview feature requires launch\_stage ALPHA or BETA. | `bool` | `false` | no |
| <a name="input_deletion_protection"></a> [deletion\_protection](#input\_deletion\_protection) | Whether to enable deletion protection on the Cloud Run service. | `bool` | `false` | no |
| <a name="input_empty_dir_volumes"></a> [empty\_dir\_volumes](#input\_empty\_dir\_volumes) | List of empty directory volumes to create and mount | <pre>list(object({<br/>    name       = string<br/>    size_limit = optional(string, "2Mi")<br/>  }))</pre> | `[]` | no |
| <a name="input_gcs_volumes"></a> [gcs\_volumes](#input\_gcs\_volumes) | List of Google Cloud Storage buckets to mount as volumes. Must ensure the Cloud Run GSA has proper IAM set on the bucket | <pre>list(object({<br/>    name      = string<br/>    bucket    = string<br/>    read_only = optional(bool, true)<br/>  }))</pre> | `[]` | no |
| <a name="input_gsa"></a> [gsa](#input\_gsa) | Service account name the Cloud Run service will run as. If empty, creates a new one. | `string` | n/a | yes |
| <a name="input_ingress"></a> [ingress](#input\_ingress) | Cloud Run ingress setting. | `string` | `"INGRESS_TRAFFIC_ALL"` | no |
| <a name="input_invokers"></a> [invokers](#input\_invokers) | List of members to grant Cloud Run invoker role | `list(string)` | <pre>[<br/>  "allUsers"<br/>]</pre> | no |
| <a name="input_labels"></a> [labels](#input\_labels) | Labels to apply to each Cloud Run service. | `map(string)` | `{}` | no |
| <a name="input_launch_stage"></a> [launch\_stage](#input\_launch\_stage) | Cloud Run launch stage for the service. | `string` | `"GA"` | no |
| <a name="input_max_instance_request_concurrency"></a> [max\_instance\_request\_concurrency](#input\_max\_instance\_request\_concurrency) | Optional maximum concurrent requests per Cloud Run instance. | `number` | `null` | no |
| <a name="input_max_instances"></a> [max\_instances](#input\_max\_instances) | Maximum number of instances to scale to | `string` | `"100"` | no |
| <a name="input_min_instances"></a> [min\_instances](#input\_min\_instances) | Minimum number of instances to keep running | `string` | `"0"` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the Cloud Run service | `string` | n/a | yes |
| <a name="input_project"></a> [project](#input\_project) | The GCP project to use | `string` | n/a | yes |
| <a name="input_regions"></a> [regions](#input\_regions) | The GCP region(s) to deploy to | `list(string)` | <pre>[<br/>  "us-east4",<br/>  "us-east5",<br/>  "us-central1",<br/>  "us-west3",<br/>  "us-west1",<br/>  "us-west4",<br/>  "us-south1",<br/>  "northamerica-northeast1",<br/>  "northamerica-northeast2",<br/>  "northamerica-south1",<br/>  "australia-southeast1",<br/>  "australia-southeast2"<br/>]</pre> | no |
| <a name="input_secrets"></a> [secrets](#input\_secrets) | List of Secret Manager secrets to mount as environment variables | <pre>list(object({<br/>    name        = string<br/>    secret_id   = string<br/>    secret_name = string<br/>  }))</pre> | `[]` | no |
| <a name="input_skipNeg"></a> [skipNeg](#input\_skipNeg) | Skip creating Network Endpoint Group and Backend Service | `bool` | `false` | no |
| <a name="input_timeout_seconds"></a> [timeout\_seconds](#input\_timeout\_seconds) | Optional request timeout for each Cloud Run service, in seconds. | `number` | `null` | no |
| <a name="input_vpc_direct_egress"></a> [vpc\_direct\_egress](#input\_vpc\_direct\_egress) | Traffic VPC egress setting. Set to `OFF`, `ALL_TRAFFIC`, or `PRIVATE_RANGES_ONLY`. | `string` | `"OFF"` | no |
| <a name="input_vpc_direct_egress_network"></a> [vpc\_direct\_egress\_network](#input\_vpc\_direct\_egress\_network) | VPC network for Direct VPC egress. Set this or vpc\_direct\_egress\_subnetwork to null to let Cloud Run infer the omitted field. | `string` | `"default"` | no |
| <a name="input_vpc_direct_egress_subnetwork"></a> [vpc\_direct\_egress\_subnetwork](#input\_vpc\_direct\_egress\_subnetwork) | VPC subnetwork from which Cloud Run receives IPs. Set this or vpc\_direct\_egress\_network to null to let Cloud Run infer the omitted field. | `string` | `"default"` | no |
| <a name="input_vpc_direct_egress_tags"></a> [vpc\_direct\_egress\_tags](#input\_vpc\_direct\_egress\_tags) | Network tags applied to this Cloud Run service | `list(string)` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_backend"></a> [backend](#output\_backend) | Backend service ID for load balancer (empty if skipNeg is true) |
| <a name="output_name"></a> [name](#output\_name) | Map of region to Cloud Run service names |
| <a name="output_url"></a> [url](#output\_url) | Primary Cloud Run service URL (first region) |
| <a name="output_urls"></a> [urls](#output\_urls) | Map of region to Cloud Run service URLs |
<!-- END_TF_DOCS -->
