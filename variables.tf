variable "name" {
  type = string
}

variable "gsa" {
  type        = string
  default     = ""
  description = "Service account name to use. If empty, creates a new one."
}

variable "min_instances" {
  type    = string
  default = "0"
}

variable "max_instances" {
  type    = string
  default = "100"
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
  default = []
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
}

variable "addl_env_vars" {
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "empty_dir_volumes" {
  type = list(object({
    name       = string
    size_limit = optional(string, "2Mi")
  }))
  default = []
}


variable "gcs_volumes" {
  type = list(object({
    name      = string
    bucket    = string
    read_only = optional(bool, true)
  }))
  default = []
}
