resource "google_cloud_run_service" "service" {
  name     = var.name
  location = var.region

  template {
    spec {
      containers {
        image = var.image
        resources {
            limits = {
                memory = "512Mi"
            }
        }
        ports {
            container_port = 8080  # Default
        }
      }
    }
  }
  traffic {
    percent         = 100
    latest_revision = true
  }
  autogenerate_revision_name = true
}

resource "google_cloud_run_service_iam_member" "noauth" {
  service  = google_cloud_run_service.service.name
  location = google_cloud_run_service.service.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}