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
