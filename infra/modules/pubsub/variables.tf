variable "topic_name" {}
variable "subscription_name" {}
variable "push_endpoint" {
  description = "URL del servicio que recibirá mensajes (opcional si es pull)"
  default     = null
}