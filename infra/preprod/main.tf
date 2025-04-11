provider "google" {
  project = "poc-serviciosgcp"    #Nombre o id proyecto
  region  = "us-central1"         #Comun para todos los recursos
}

# Almacenar remotamente (bucket gcp), inventario terraform proyecto 
terraform {
  backend "gcs" {
    bucket = "conf-terraform"
    prefix = "estado/infra"
  }
}

# Habilitando APIs necesarias para el modelo, parte 1
resource "google_project_service" "run" {
  service = "run.googleapis.com"
}
resource "google_project_service" "vpcaccess" {
  service = "vpcaccess.googleapis.com"
}
resource "google_project_service" "storage" {
  service = "storage.googleapis.com"
}

# Acceder a recursos internos e internet en los CRun, necesario definir recurso vpc connector y red
resource "google_vpc_access_connector" "vpc_connector_crun" {
  name         = "vpc-connector-crun"
  network      = "default"
  region       = "us-central1"
  ip_cidr_range = "10.8.0.0/28"
}

module "run_1" {
  source = "../modules/cloud_run"
  name   = "cloud-run-feed"
  image  = "gcr.io/cloudrun/hello:latest"
  region = "us-central1"
}

module "run_2" {
  source = "../modules/cloud_run"
  name   = "cloud-run-normaliza"
  image  = "gcr.io/cloudrun/hello:latest"
  region = "us-central1"
}

module "bucket_1" {
  source = "../modules/storage"
  name   = "extraccion-seguro"
  region = "US"
}

module "bucket_2" {
  source = "../modules/storage"
  name   = "normalizacion-seguro"
  region = "US"
}

#Caso de uso pub/sub, notificacion de eventos
#Las acciones en los casos de uso (4notasde2cu), envian o PUSH mensajes a cada topico (endpoint http)
#Los subscriptores consumen esos mensajes del topico a nivel de PULL y generan acciones
#Mensajes se almacenan hasta que sean entregados o expiren
#Es una infraestrcutura escalable a nivel de Servless o instancia (cloud run)
module "pubsub_1" {
  source             = "../modules/pubsub"
  topic_name         = "tarj_expuestas_vigentes"
  subscription_name  = "sub_tarj_expuestas_vigentes"
  push_endpoint      = "https://run-1-staging-abc.a.run.app/"
}

module "pubsub_2" {
  source             = "../modules/pubsub"
  topic_name         = "reinsistencia_tarj_expuestas_vigentes"
  subscription_name  = "sub_reinsistencia_tarj_expuestas_vigentes"
  push_endpoint      = "https://run-2-staging-abc.a.run.app/"
}

#**En caso de PROD, mismo contenido que preProd, solo cambian nombres de servicios, buckets e imágenes a versión productiva y el project.