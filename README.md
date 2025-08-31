# terraform-cloudrun-v2

Terraform module for a multi-region [Google Cloud Run v2 Service](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_run_v2_service) behind a [serverless Network Endpoint Group (NEG)](https://cloud.google.com/load-balancing/docs/negs/serverless-neg-concepts).

Variables support GPUs, GCS mounts, multi-containers.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_google"></a> [google](#requirement\_google) | ~> 6.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | ~> 6.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [google_cloud_run_v2_service.cloudrun](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_run_v2_service) | resource |
| [google_cloud_run_v2_service_iam_member.invoker](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_run_v2_service_iam_member) | resource |
| [google_compute_backend_service.backend](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_backend_service) | resource |
| [google_compute_region_network_endpoint_group.neg](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_region_network_endpoint_group) | resource |
| [google_project_iam_member.sa_role](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_service_account.service_account](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account) | resource |
| [google_service_account.service_account](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/service_account) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_addl_env_vars"></a> [addl\_env\_vars](#input\_addl\_env\_vars) | Additional environment variables to set in containers | <pre>list(object({<br/>    name  = string<br/>    value = string<br/>  }))</pre> | `[]` | no |
| <a name="input_containers"></a> [containers](#input\_containers) | List of container configurations to run in the service. At least one container needs a port. This allows easily configuring multi-container deployments. | <pre>list(object({<br/>    image          = string<br/>    name           = string<br/>    command        = optional(list(string), null)<br/>    args           = optional(list(string), null)<br/>    port           = optional(number, 0)<br/>    memory         = optional(string, "512Mi")<br/>    cpu            = optional(string, "1000m")<br/>    liveness_probe = optional(string, "")<br/>    gpus           = optional(string, "")<br/>    volume_mounts = optional(list(object({<br/>      name       = string<br/>      mount_path = string<br/>    })), [])<br/>  }))</pre> | n/a | yes |
| <a name="input_empty_dir_volumes"></a> [empty\_dir\_volumes](#input\_empty\_dir\_volumes) | List of empty directory volumes to create and mount | <pre>list(object({<br/>    name       = string<br/>    size_limit = optional(string, "2Mi")<br/>  }))</pre> | `[]` | no |
| <a name="input_gcs_volumes"></a> [gcs\_volumes](#input\_gcs\_volumes) | List of Google Cloud Storage buckets to mount as volumes. Must ensure the Cloud Run GSA has proper IAM set on the bucket | <pre>list(object({<br/>    name      = string<br/>    bucket    = string<br/>    read_only = optional(bool, true)<br/>  }))</pre> | `[]` | no |
| <a name="input_gsa"></a> [gsa](#input\_gsa) | Service account name the Cloud Run service will run as. If empty, creates a new one. | `string` | `""` | no |
| <a name="input_invokers"></a> [invokers](#input\_invokers) | List of members to grant Cloud Run invoker role | `list(string)` | <pre>[<br/>  "allUsers"<br/>]</pre> | no |
| <a name="input_max_instances"></a> [max\_instances](#input\_max\_instances) | Maximum number of instances to scale to | `string` | `"100"` | no |
| <a name="input_min_instances"></a> [min\_instances](#input\_min\_instances) | Minimum number of instances to keep running | `string` | `"0"` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the Cloud Run service | `string` | n/a | yes |
| <a name="input_project"></a> [project](#input\_project) | The GCP project to use | `string` | n/a | yes |
| <a name="input_regions"></a> [regions](#input\_regions) | The GCP region(s) to deploy to | `list(string)` | <pre>[<br/>  "us-east4",<br/>  "us-east5",<br/>  "us-central1",<br/>  "us-west3",<br/>  "us-west1",<br/>  "us-west4",<br/>  "us-south1",<br/>  "northamerica-northeast1",<br/>  "northamerica-northeast2",<br/>  "northamerica-south1",<br/>  "australia-southeast1",<br/>  "australia-southeast2"<br/>]</pre> | no |
| <a name="input_secrets"></a> [secrets](#input\_secrets) | List of Secret Manager secrets to mount as environment variables | <pre>list(object({<br/>    name        = string<br/>    secret_id   = string<br/>    secret_name = string<br/>  }))</pre> | `[]` | no |
| <a name="input_skipNeg"></a> [skipNeg](#input\_skipNeg) | Skip creating Network Endpoint Group and Backend Service | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_backend"></a> [backend](#output\_backend) | Backend service ID for load balancer (empty if skipNeg is true) |
| <a name="output_gsa"></a> [gsa](#output\_gsa) | Name of the service account used by Cloud Run |
| <a name="output_gsaEmail"></a> [gsaEmail](#output\_gsaEmail) | Email address of the service account used by Cloud Run |
| <a name="output_name"></a> [name](#output\_name) | Map of region to Cloud Run service names |
| <a name="output_url"></a> [url](#output\_url) | Primary Cloud Run service URL (first region) |
| <a name="output_urls"></a> [urls](#output\_urls) | Map of region to Cloud Run service URLs |
<!-- END_TF_DOCS -->