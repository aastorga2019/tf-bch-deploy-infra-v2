resource "google_vpc_access_connector" "connector" {
  name          = var.vpc_connector_name
  subnet {
    name = google_compute_subnetwork.custom_test.name
  }
  machine_type = "e2-standard-4"   # Default=e2-micro
  min_instances = 2                 #OJO... entte 2 y 9
  max_instances = 3                 #OJO... entre 3 y 10 instancia autoscaling
}

resource "google_compute_subnetwork" "custom_test" {
  name          = var.vpc_connector_name
  ip_cidr_range = var.ip_cidr_range
  region        = var.region
  network       = var.network
}

resource "google_cloud_run_v2_service" "service" {
  name     = var.service_name
  location = var.region

  #Para no bloquear el destroiy en algunos recursos, ideal true en PROD
  deletion_protection = false
  
  template {
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
  }
  traffic {
    percent         = 100
    type = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
  }
  
}

resource "google_cloud_run_service_iam_member" "invoker" {
  service        = google_cloud_run_v2_service.service.name
  role           = "roles/run.invoker"
  member         = "allUsers"
}
