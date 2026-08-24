terraform {
  required_providers {
    grafana = {
      source  = "grafana/grafana"
      version = ">= 4.8.0"
    }
  }
}

# Parse .env into a map
locals {
  env = {
    for tuple in regexall("(.*?)=(.*)", file("${abspath("${path.module}/../.env")}")) :
    trim(tuple[0], " \t\n\r") => trim(tuple[1], " \t\n\r")
  }
}

# Assign local vars from env map
locals {
  stack_slug                = local.env["STACK_SLUG"]
  cloud_region              = local.env["CLOUD_REGION"]
  cloud_access_policy_token = local.env["CLOUD_ACCESS_POLICY_TOKEN"]
}

# Configure the Grafana Cloud provider
provider "grafana" {
  alias                     = "cloud"
  cloud_access_policy_token = local.cloud_access_policy_token
}

data "grafana_cloud_stack" "testing_stack" {
  provider = grafana.cloud
  slug     = local.stack_slug
}

resource "grafana_cloud_stack_service_account" "testing_sa" {
  provider   = grafana.cloud
  stack_slug = local.stack_slug

  name        = "${local.stack_slug}-terraform-sa"
  role        = "Admin"
  is_disabled = false
}

resource "grafana_cloud_stack_service_account_token" "testing_sa_token" {
  provider   = grafana.cloud
  stack_slug = local.stack_slug

  name               = "${local.stack_slug}-terraform-sa-token"
  service_account_id = grafana_cloud_stack_service_account.testing_sa.id
}

resource "grafana_cloud_access_policy" "sm_metrics_publish" {
  provider = grafana.cloud

  region = local.cloud_region
  name   = "metric-publisher-for-sm-${local.stack_slug}"
  scopes = ["metrics:write", "stacks:read", "logs:write", "traces:write"]
  realm {
    type       = "stack"
    identifier = data.grafana_cloud_stack.testing_stack.id
  }
}

resource "grafana_cloud_access_policy_token" "sm_metrics_publish" {
  provider = grafana.cloud

  region           = local.cloud_region
  access_policy_id = grafana_cloud_access_policy.sm_metrics_publish.policy_id
  name             = "metric-publisher-for-sm-${local.stack_slug}"
}

# Install GCk6 app. If the app is already installed, this step is a no-op.
resource "grafana_k6_installation" "k6_installation" {
  provider = grafana.cloud

  cloud_access_policy_token = local.cloud_access_policy_token
  stack_id                  = data.grafana_cloud_stack.testing_stack.id
  grafana_sa_token          = grafana_cloud_stack_service_account_token.testing_sa_token.key
  grafana_user              = "admin"
}

# Install Synthetic Monitoring app. If the app is already installed, this step is a no-op.
resource "grafana_synthetic_monitoring_installation" "sm_installation" {
  provider = grafana.cloud

  stack_id              = data.grafana_cloud_stack.testing_stack.id
  metrics_publisher_key = grafana_cloud_access_policy_token.sm_metrics_publish.token
}

provider "grafana" {
  url             = data.grafana_cloud_stack.testing_stack.url
  auth            = grafana_cloud_stack_service_account_token.testing_sa_token.key
  stack_id        = data.grafana_cloud_stack.testing_stack.id
  k6_access_token = grafana_k6_installation.k6_installation.k6_access_token
  sm_access_token = grafana_synthetic_monitoring_installation.sm_installation.sm_access_token
  sm_url          = grafana_synthetic_monitoring_installation.sm_installation.stack_sm_api_url
}