variable "name" {
  type        = string
  description = "Name of the Cloud Run service"
}

variable "gsa" {
  type        = string
  default     = ""
  description = "Service account name the Cloud Run service will run as. If empty, creates a new one."
}

variable "min_instances" {
  type        = string
  default     = "0"
  description = "Minimum number of instances to keep running"
}

variable "max_instances" {
  type        = string
  default     = "100"
  description = "Maximum number of instances to scale to"
}

variable "regions" {
  type        = list(string)
  description = "The GCP region(s) to deploy to"
  default = [
    "us-east4",
    "us-east5",
    "us-central1",
    "us-west3",
    "us-west1",
    "us-west4",
    "us-south1",
    "northamerica-northeast1",
    "northamerica-northeast2",
    "northamerica-south1",
    "australia-southeast1",
    "australia-southeast2"
  ]
}

variable "project" {
  type        = string
  description = "The GCP project to use"
}

variable "skipNeg" {
  type        = bool
  default     = false
  description = "Skip creating Network Endpoint Group and Backend Service"
}

variable "invokers" {
  type        = list(string)
  default     = ["allUsers"]
  description = "List of members to grant Cloud Run invoker role"
}

variable "secrets" {
  type = list(object({
    name        = string
    secret_id   = string
    secret_name = string
  }))
  default     = []
  description = "List of Secret Manager secrets to mount as environment variables"
}

variable "containers" {
  type = list(object({
    image          = string
    name           = string
    command        = optional(list(string), null)
    args           = optional(list(string), null)
    port           = optional(number, 0)
    memory         = optional(string, "512Mi")
    cpu            = optional(string, "1000m")
    liveness_probe = optional(string, "")
    gpus           = optional(string, "")
    volume_mounts = optional(list(object({
      name       = string
      mount_path = string
    })), [])
  }))
  description = "List of container configurations to run in the service. At least one container needs a port. This allows easily configuring multi-container deployments."
}

variable "addl_env_vars" {
  type = list(object({
    name  = string
    value = string
  }))
  default     = []
  description = "Additional environment variables to set in containers"
}

variable "empty_dir_volumes" {
  type = list(object({
    name       = string
    size_limit = optional(string, "2Mi")
  }))
  default     = []
  description = "List of empty directory volumes to create and mount"
}


variable "gcs_volumes" {
  type = list(object({
    name      = string
    bucket    = string
    read_only = optional(bool, true)
  }))
  default     = []
  description = "List of Google Cloud Storage buckets to mount as volumes. Must ensure the Cloud Run GSA has proper IAM set on the bucket"
}
