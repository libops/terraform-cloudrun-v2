mock_provider "google" {
  mock_data "google_service_account" {
    defaults = {
      email = "cloudrun@example-project.iam.gserviceaccount.com"
    }
  }
}

variables {
  name     = "example"
  gsa      = "cloudrun"
  project  = "example-project"
  regions  = ["us-central1"]
  skipNeg  = true
  invokers = []
  containers = [{
    image = "us-docker.pkg.dev/cloudrun/container/hello"
    name  = "app"
    port  = 8080
  }]
}

run "direct_vpc_off" {
  command = plan

  assert {
    condition     = length(google_cloud_run_v2_service.cloudrun["us-central1"].template[0].vpc_access) == 0
    error_message = "vpc_access must be omitted when Direct VPC egress is off."
  }
}

run "direct_vpc_preserves_default_interface" {
  command = plan

  variables {
    vpc_direct_egress = "PRIVATE_RANGES_ONLY"
  }

  assert {
    condition = (
      google_cloud_run_v2_service.cloudrun["us-central1"].template[0].vpc_access[0].network_interfaces[0].network == "default"
      && google_cloud_run_v2_service.cloudrun["us-central1"].template[0].vpc_access[0].network_interfaces[0].subnetwork == "default"
    )
    error_message = "The compatible default network and subnetwork must be preserved."
  }
}

run "direct_vpc_network_only" {
  command = plan

  variables {
    vpc_direct_egress            = "PRIVATE_RANGES_ONLY"
    vpc_direct_egress_network    = "projects/example-project/global/networks/app"
    vpc_direct_egress_subnetwork = null
  }

  assert {
    condition     = google_cloud_run_v2_service.cloudrun["us-central1"].template[0].vpc_access[0].network_interfaces[0].network == "projects/example-project/global/networks/app"
    error_message = "The configured network must be rendered."
  }

  assert {
    condition     = local.vpc_direct_egress_subnetwork == null
    error_message = "An omitted subnetwork must be passed to the provider as null."
  }
}

run "direct_vpc_subnetwork_only" {
  command = plan

  variables {
    vpc_direct_egress            = "ALL_TRAFFIC"
    vpc_direct_egress_network    = null
    vpc_direct_egress_subnetwork = "projects/example-project/regions/us-central1/subnetworks/app"
  }

  assert {
    condition     = local.vpc_direct_egress_network == null
    error_message = "An omitted network must be passed to the provider as null."
  }

  assert {
    condition     = google_cloud_run_v2_service.cloudrun["us-central1"].template[0].vpc_access[0].network_interfaces[0].subnetwork == "projects/example-project/regions/us-central1/subnetworks/app"
    error_message = "The configured subnetwork must be rendered."
  }
}

run "direct_vpc_rejects_subnetwork_from_another_region" {
  command = plan

  variables {
    vpc_direct_egress            = "PRIVATE_RANGES_ONLY"
    vpc_direct_egress_network    = "projects/example-project/global/networks/app"
    vpc_direct_egress_subnetwork = "projects/example-project/regions/us-east1/subnetworks/app"
  }

  expect_failures = [
    google_cloud_run_v2_service.cloudrun["us-central1"],
  ]
}

run "direct_vpc_rejects_one_regional_subnetwork_for_multiple_regions" {
  command = plan

  variables {
    regions                      = ["us-central1", "us-east1"]
    vpc_direct_egress            = "PRIVATE_RANGES_ONLY"
    vpc_direct_egress_network    = "projects/example-project/global/networks/app"
    vpc_direct_egress_subnetwork = "projects/example-project/regions/us-central1/subnetworks/app"
  }

  expect_failures = [
    google_cloud_run_v2_service.cloudrun["us-east1"],
  ]
}

run "direct_vpc_network_and_subnetwork" {
  command = plan

  variables {
    vpc_direct_egress            = "PRIVATE_RANGES_ONLY"
    vpc_direct_egress_network    = "app"
    vpc_direct_egress_subnetwork = "app-us-central1"
  }

  assert {
    condition = (
      google_cloud_run_v2_service.cloudrun["us-central1"].template[0].vpc_access[0].network_interfaces[0].network == "app"
      && google_cloud_run_v2_service.cloudrun["us-central1"].template[0].vpc_access[0].network_interfaces[0].subnetwork == "app-us-central1"
    )
    error_message = "Both network interface fields must be rendered when configured."
  }
}

run "direct_vpc_requires_an_interface" {
  command = plan

  variables {
    vpc_direct_egress            = "PRIVATE_RANGES_ONLY"
    vpc_direct_egress_network    = null
    vpc_direct_egress_subnetwork = null
  }

  expect_failures = [
    google_cloud_run_v2_service.cloudrun,
  ]
}

run "legacy_startup_probe_path" {
  command = plan

  variables {
    containers = [{
      image         = "us-docker.pkg.dev/cloudrun/container/hello"
      name          = "app"
      port          = 8080
      startup_probe = "/legacy-startup"
    }]
  }

  assert {
    condition     = google_cloud_run_v2_service.cloudrun["us-central1"].template[0].containers[0].startup_probe[0].http_get[0].path == "/legacy-startup"
    error_message = "The legacy startup_probe string must continue to render an HTTP probe."
  }
}

run "structured_startup_probe" {
  command = plan

  variables {
    containers = [{
      image         = "us-docker.pkg.dev/cloudrun/container/hello"
      name          = "app"
      port          = 8080
      startup_probe = "ignored-legacy-startup"
      startup_probe_config = {
        path                  = "/startup"
        initial_delay_seconds = 12
        timeout_seconds       = 4
        period_seconds        = 8
        failure_threshold     = 20
      }
    }]
  }

  assert {
    condition = (
      google_cloud_run_v2_service.cloudrun["us-central1"].template[0].containers[0].startup_probe[0].http_get[0].path == "/startup"
      && google_cloud_run_v2_service.cloudrun["us-central1"].template[0].containers[0].startup_probe[0].initial_delay_seconds == 12
      && google_cloud_run_v2_service.cloudrun["us-central1"].template[0].containers[0].startup_probe[0].timeout_seconds == 4
      && google_cloud_run_v2_service.cloudrun["us-central1"].template[0].containers[0].startup_probe[0].period_seconds == 8
      && google_cloud_run_v2_service.cloudrun["us-central1"].template[0].containers[0].startup_probe[0].failure_threshold == 20
    )
    error_message = "The structured startup probe must render all configured HTTP probe fields."
  }
}

run "legacy_startup_probe_rejects_non_absolute_path" {
  command = plan

  variables {
    containers = [{
      image         = "us-docker.pkg.dev/cloudrun/container/hello"
      name          = "app"
      startup_probe = "startup"
    }]
  }

  expect_failures = [
    var.containers,
  ]
}

run "startup_probe_rejects_initial_delay_out_of_range" {
  command = plan

  variables {
    containers = [{
      image = "us-docker.pkg.dev/cloudrun/container/hello"
      name  = "app"
      startup_probe_config = {
        path                  = "/startup"
        initial_delay_seconds = 241
      }
    }]
  }

  expect_failures = [
    var.containers,
  ]
}

run "startup_probe_rejects_empty_path" {
  command = plan

  variables {
    containers = [{
      image = "us-docker.pkg.dev/cloudrun/container/hello"
      name  = "app"
      startup_probe_config = {
        path = ""
      }
    }]
  }

  expect_failures = [
    var.containers,
  ]
}

run "startup_probe_rejects_non_absolute_path" {
  command = plan

  variables {
    containers = [{
      image = "us-docker.pkg.dev/cloudrun/container/hello"
      name  = "app"
      startup_probe_config = {
        path = "startup"
      }
    }]
  }

  expect_failures = [
    var.containers,
  ]
}

run "startup_probe_rejects_whitespace_in_path" {
  command = plan

  variables {
    containers = [{
      image = "us-docker.pkg.dev/cloudrun/container/hello"
      name  = "app"
      startup_probe_config = {
        path = "/startup probe"
      }
    }]
  }

  expect_failures = [
    var.containers,
  ]
}

run "startup_probe_rejects_timeout_greater_than_period" {
  command = plan

  variables {
    containers = [{
      image = "us-docker.pkg.dev/cloudrun/container/hello"
      name  = "app"
      startup_probe_config = {
        path            = "/startup"
        timeout_seconds = 11
        period_seconds  = 10
      }
    }]
  }

  expect_failures = [
    var.containers,
  ]
}

run "startup_probe_rejects_failure_window_over_240_seconds" {
  command = plan

  variables {
    containers = [{
      image = "us-docker.pkg.dev/cloudrun/container/hello"
      name  = "app"
      startup_probe_config = {
        path              = "/startup"
        period_seconds    = 20
        failure_threshold = 13
      }
    }]
  }

  expect_failures = [
    var.containers,
  ]
}
