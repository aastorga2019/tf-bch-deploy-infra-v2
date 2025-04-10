resource "google_pubsub_topic" "topic" {
  name = var.topic_name
}

resource "google_pubsub_subscription" "subscription" {
  name                 = var.subscription_name
  topic                = google_pubsub_topic.topic.name
  ack_deadline_seconds = 20   #tiempo expiracion mensaje

  push_config {
    push_endpoint = var.push_endpoint
  }
}
