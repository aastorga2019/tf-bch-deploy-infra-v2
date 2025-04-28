##### Almacenar seguro remotamente (bucket gcp), inventario terraform proyecto 
terraform {
  backend "gcs" {
    bucket = "conf-terraform"
    prefix = "estado/infra"
  }
}

##### Declarar elproyecto a trabajar
provider "google" {
  project = "poc-serviciosgcp"
  region  = "us-central1" #Comun para todos los recursos
}

##### Habilitando APIs necesarias para el modelo, parte 1
resource "google_project_service" "container_registry" {
  service = "containerregistry.googleapis.com"
}

resource "google_project_service" "run" {
  service = "run.googleapis.com"
}

# Fue necesario habilitar este vpcaccess api, manual primero...
resource "google_project_service" "vpcaccess" {
  service = "vpcaccess.googleapis.com"
}

#resource "google_project_service" "storage" {
#  service = "storage.googleapis.com"
#}
#
#resource "google_project_service" "dataplex" {
#  service = "dataplex.googleapis.com"
#}
#### OJO, pueden haber mas API para habilitar, a medida que cresca el proyecto

######## Manejo de Modulos
module "run_1" {
  service_name = "crun-tarjetas"
  vpc_connector_name = "conector-crun-feed"
  source = "../modules/cloud_run"
  region = "us-central1"
  image  = "gcr.io/cloudrun/hello:latest"
  network            = "default"      # hay que asignarlo, deja en Default
  ip_cidr_range      = "10.5.0.0/28"  # Segun lo que entreguen
  
  depends_on = [      # Esperar que APIs relacionadas se activen, antes de crear recurso
    google_project_service.run,
    google_project_service.vpcaccess
  ]
}

module "run_2" {
  service_name = "crun-trafico"
  vpc_connector_name = "conector-crun-normaliza"
  source = "../modules/cloud_run"
  region = "us-central1"
  image  = "gcr.io/cloudrun/hello:latest"
  network            = "default"
  ip_cidr_range      = "10.6.0.0/28"        # Segun lo que entreguen
  
  depends_on = [      # Esperar que API se active, antes de crear conector
    google_project_service.vpcaccess
  ]
}

#module "run_3" {
#  vpc_connector_name = "conector-crun-notifica"
#  source = "../modules/cloud_run"
#  region = "us-central1"
#  image  = "gcr.io/cloudrun/hello:latest"
#  service_name = "crun-notificacion"
#  network            = "default"
#  ip_cidr_range      = "10.5.0.0/28"        # Segun lo que entreguen
#}

#module "bucket_2" {
#  source = "../modules/storage"
#  name   = "normalizacion-seguro"
#  region = "US"
#}

module "secret_api_key" {
  source        = "../modules/secret_manager"
  secret_id     = "uciaa_exposed_card"
  secret_value  = "Cambia este valor, cuando te falle uso secreto"
}

##########Caso de uso pub/sub, notificacion de eventos
#Las acciones en los casos de uso (4notasde2cu), envian o PUSH mensajes a cada topico (endpoint http)
#Los subscriptores consumen esos mensajes del topico a nivel de PULL y generan acciones
#Mensajes se almacenan hasta que sean entregados o expiren
#Es una infraestrcutura escalable a nivel de Servless o instancia (cloud run)
#
#Tal vez, no se usen porque hay un Cloud Run de Notificaciones, comentar code ahora y verlo a futuro
#module "pubsub_1" {
#  source             = "../modules/pubsub"
#  topic_name         = "tarj_expuestas_vigentes"
#  subscription_name  = "sub_tarj_expuestas_vigentes"
#  push_endpoint      = "https://run-1-staging-abc.a.run.app/"
#}
#
#module "pubsub_2" {
#  source             = "../modules/pubsub"
#  topic_name         = "reinsistencia_tarj_expuestas_vigentes"
#  subscription_name  = "sub_reinsistencia_tarj_expuestas_vigentes"
#  push_endpoint      = "https://run-2-staging-abc.a.run.app/"
#}
#
######### Trabajando con Dataplex o Catalogo de datos
#Crear un lake ppal y necesario
#resource "google_dataplex_lake" "main_lake" {
#  name        = "mi-lake"
#  project     = var.project_id
#  location    = var.region
#  display_name = "Lago de datos principal"
#  description  = "Contiene datos analíticos"
#}
#
#Crear una Zona dentro del lake
#resource "google_dataplex_zone" "raw_zone" {
#  name         = "zona-raw"
#  lake         = google_dataplex_lake.main_lake.name
#  project      = var.project_id
#  location     = var.region
#  display_name = "Zona Raw"
#  type         = "RAW"
#
#  discovery_spec {
#    enabled = true
#    include_patterns = ["*"]
#  }
#
#  resource_spec {
#    location_type = "SINGLE_REGION"
#  }
#}
#
#Agregar un Asset=Activo (GCS o BQ) a la Zona
#Para GCS
#resource "google_dataplex_asset" "storage_asset" {
#  name         = "gcs-dataset"
#  lake         = google_dataplex_lake.main_lake.name
#  zone         = google_dataplex_zone.raw_zone.name
#  project      = var.project_id
#  location     = var.region
#  display_name = "Asset GCS"
#
#  discovery_spec {   # Hace descubrimiento Automatico de data
#    enabled = true
#  }
#
#  resource_spec {
#    name         = "projects/${var.project_id}/locations/${var.region}/lakes/${google_dataplex_lake.main_lake.name}/zones/${google_dataplex_zone.raw_zone.name}/assets/gcs-dataset"
#    type         = "STORAGE_BUCKET"
#    project      = var.project_id
#    location_type = "SINGLE_REGION"
#  }
#
#  gcs_path {
#    file_path = "gs://tu-bucket/datos/"
#  }
#}
#
#Para BQ 
#resource "google_dataplex_asset" "bq_asset" {
#  name         = "bigquery-dataset"
#  lake         = google_dataplex_lake.main_lake.name
#  zone         = google_dataplex_zone.raw_zone.name
#  project      = var.project_id
#  location     = var.region
#  display_name = "BQ Asset"
#
#  discovery_spec { 
#    enabled = true
#  }
#
#  resource_spec {
#    type = "BIGQUERY_DATASET"
#    name = "projects/${var.project_id}/datasets/mi_dataset"
#  }
#}
#
#Variables comunes
#variable "project_id" {}
#variable "region" {
#  default = "us-central1"
#}
#Importante: Use tags o clasificacion de datos para ayudar en gobernznas ( PII, Confidencial, etc)
#
#
#**En caso de PROD, mismo contenido que preProd, solo cambian nombres de servicios, buckets e imágenes a versión productiva y el project.