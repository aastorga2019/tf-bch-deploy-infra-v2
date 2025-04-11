resource "google_storage_bucket" "bucket" {
  name          = var.name
  location      = var.region
  storage_class = "STANDARD"
  uniform_bucket_level_access = true    # Bloquea el acceso público
#  force_destroy = false

  versioning {
    enabled = true
  }
}

resource "google_project_iam_member" "storage_access" {
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_cloud_run_service.service.template[0].spec[0].service_account_name}"
}
