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
                cpu = "1"
            }
        }
        ports {
            container_port = 8080  # Default
        }
      }
      vpc_access {
        connector = google_vpc_access_connector.vpc_connector_crun.id
        egress    = "ALL_TRAFFIC"   # Permite salida a internet y acceso a otras redes
      }
    }

#    metadata {
#      annotations = {
#        "run.googleapis.com/cloudsql-instances" = "my-project:us-central1:my-sql-instance"
#      }
#    }

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
