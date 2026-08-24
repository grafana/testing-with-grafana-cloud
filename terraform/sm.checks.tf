# Define synthetic monitoring checks

data "grafana_synthetic_monitoring_probes" "main" {
  depends_on = [grafana_synthetic_monitoring_installation.sm_installation]
}

resource "grafana_synthetic_monitoring_check" "http" {
  job     = "Validate that the web app is up"
  target  = "https://quickpizza.grafana.com/"
  enabled = true
  probes = [
    data.grafana_synthetic_monitoring_probes.main.probes.Ohio,
    data.grafana_synthetic_monitoring_probes.main.probes.Paris,
  ]
  labels = {
    environment = "production"
    team = "backend"
  }
  settings {
    http {}
  }
}

resource "grafana_synthetic_monitoring_check" "scripted" {
  job     = "Validate that getting a pizza recommendation works"
  target  = "https://quickpizza.grafana.com/"
  enabled = true
  probes = [
    data.grafana_synthetic_monitoring_probes.main.probes.Ohio,
    data.grafana_synthetic_monitoring_probes.main.probes.Paris,
  ]
  labels = {
    environment = "production",
    team = "backend"
  }
  settings {
    scripted {
      script = file("${path.module}/../dist/backend/get_recommendation.js" )
    }
  }
}

resource "grafana_synthetic_monitoring_check" "scripted_browser" {
  job     = "Validate that getting a pizza recommendation works in the browser"
  target  = "https://quickpizza.grafana.com/"
  enabled = true
  probes = [
    data.grafana_synthetic_monitoring_probes.main.probes.Ohio,
    data.grafana_synthetic_monitoring_probes.main.probes.Paris,
  ]
  labels = {
    environment = "production"
    team = "frontend"
  }
  settings {
    browser {
      script = file("${path.module}/../src/web_app/get_recommendation.ts" )
    }
  }
}