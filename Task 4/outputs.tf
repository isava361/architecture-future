# ═══════════════════════════════════════════════════════════════
# outputs.tf — ключевые параметры развёрнутой инфраструктуры
# ═══════════════════════════════════════════════════════════════

# ─────────────────────────────────────────────────────────────────
# Сеть
# ─────────────────────────────────────────────────────────────────

output "network_id" {
  description = "ID VPC-сети"
  value       = yandex_vpc_network.main.id
}

output "network_name" {
  description = "Имя VPC-сети"
  value       = yandex_vpc_network.main.name
}

output "subnet_ids" {
  description = "ID подсетей по доменам"
  value = {
    medical     = yandex_vpc_subnet.medical.id
    fintech     = yandex_vpc_subnet.fintech.id
    ai          = yandex_vpc_subnet.ai.id
    analytics   = yandex_vpc_subnet.analytics.id
    k8s         = yandex_vpc_subnet.k8s.id
    integration = yandex_vpc_subnet.integration.id
  }
}

output "nat_gateway_id" {
  description = "ID NAT Gateway (для привязки к новым подсетям)"
  value       = yandex_vpc_gateway.nat.id
}

# ─────────────────────────────────────────────────────────────────
# Compute Instances
# ─────────────────────────────────────────────────────────────────

output "medical_api_internal_ip" {
  description = "Внутренний IP Medical API сервера"
  value       = yandex_compute_instance.medical_api.network_interface[0].ip_address
}

output "fintech_api_internal_ip" {
  description = "Внутренний IP Fintech API сервера"
  value       = yandex_compute_instance.fintech_api.network_interface[0].ip_address
}

output "medical_api_instance_id" {
  description = "ID инстанса Medical API"
  value       = yandex_compute_instance.medical_api.id
}

output "fintech_api_instance_id" {
  description = "ID инстанса Fintech API"
  value       = yandex_compute_instance.fintech_api.id
}

# ─────────────────────────────────────────────────────────────────
# Managed Kafka
# ─────────────────────────────────────────────────────────────────

output "kafka_cluster_id" {
  description = "ID Kafka-кластера"
  value       = yandex_mdb_kafka_cluster.main.id
}

output "kafka_bootstrap_servers" {
  description = "Bootstrap servers для Kafka-клиентов"
  value       = "${yandex_mdb_kafka_cluster.main.id}.mdb.yandexcloud.net:9092"
}

output "kafka_topics" {
  description = "Список созданных Kafka-топиков"
  value = [
    yandex_mdb_kafka_topic.medical_events.name,
    yandex_mdb_kafka_topic.fintech_events.name,
    yandex_mdb_kafka_topic.partners_pharma.name,
    yandex_mdb_kafka_topic.partners_devices.name,
  ]
}

# ─────────────────────────────────────────────────────────────────
# Object Storage (Medical Data Lake)
# ─────────────────────────────────────────────────────────────────

output "medical_datalake_bucket" {
  description = "Имя S3-бакета медицинского Data Lake"
  value       = yandex_storage_bucket.medical_datalake.bucket
}

output "medical_datalake_endpoint" {
  description = "S3 endpoint для доступа к медицинскому Data Lake"
  value       = "https://storage.yandexcloud.net/${yandex_storage_bucket.medical_datalake.bucket}"
}

# ─────────────────────────────────────────────────────────────────
# ClickHouse (Corporate DWH)
# ─────────────────────────────────────────────────────────────────

output "clickhouse_cluster_id" {
  description = "ID ClickHouse-кластера (Corporate DWH)"
  value       = yandex_mdb_clickhouse_cluster.dwh.id
}

output "clickhouse_fqdn" {
  description = "FQDN ClickHouse для подключения (порт 8443 HTTPS, 9440 native TLS)"
  value       = "${yandex_mdb_clickhouse_cluster.dwh.id}.mdb.yandexcloud.net"
}

# ─────────────────────────────────────────────────────────────────
# PostgreSQL (Финтех-домен)
# ─────────────────────────────────────────────────────────────────

output "pg_cluster_id" {
  description = "ID PostgreSQL-кластера финтех-домена"
  value       = yandex_mdb_postgresql_cluster.fintech.id
}

output "pg_fqdn" {
  description = "FQDN PostgreSQL для подключения финтех-сервисов"
  value       = "${yandex_mdb_postgresql_cluster.fintech.id}.mdb.yandexcloud.net"
}

output "pg_connection_string" {
  description = "Connection string PostgreSQL (чувствительный)"
  value       = "postgresql://${var.pg_admin_user}@${yandex_mdb_postgresql_cluster.fintech.id}.mdb.yandexcloud.net:6432/fintechdb?sslmode=verify-full"
  sensitive   = true
}

# ─────────────────────────────────────────────────────────────────
# Kubernetes
# ─────────────────────────────────────────────────────────────────

output "k8s_cluster_id" {
  description = "ID Kubernetes-кластера"
  value       = yandex_kubernetes_cluster.main.id
}

output "k8s_cluster_external_endpoint" {
  description = "Публичный endpoint API-сервера Kubernetes"
  value       = yandex_kubernetes_cluster.main.master[0].external_v4_endpoint
}

output "k8s_connect_command" {
  description = "Команда для получения kubeconfig через yc CLI"
  value       = "yc managed-kubernetes cluster get-credentials --id ${yandex_kubernetes_cluster.main.id} --external"
}

# ─────────────────────────────────────────────────────────────────
# Container Registry
# ─────────────────────────────────────────────────────────────────

output "registry_id" {
  description = "ID Container Registry"
  value       = yandex_container_registry.main.id
}

output "registry_endpoint" {
  description = "Endpoint Container Registry для docker push/pull"
  value       = "cr.yandex/${yandex_container_registry.main.id}"
}

# ─────────────────────────────────────────────────────────────────
# API Gateway
# ─────────────────────────────────────────────────────────────────

output "api_gateway_id" {
  description = "ID API Gateway"
  value       = yandex_api_gateway.main.id
}

output "api_gateway_domain" {
  description = "Публичный домен API Gateway (единая точка входа)"
  value       = yandex_api_gateway.main.domain
}

# ─────────────────────────────────────────────────────────────────
# Lockbox (секреты)
# ─────────────────────────────────────────────────────────────────

output "lockbox_pg_secret_id" {
  description = "ID секрета с паролем PostgreSQL в Lockbox"
  value       = yandex_lockbox_secret.pg_password.id
}

output "lockbox_ch_secret_id" {
  description = "ID секрета с паролем ClickHouse в Lockbox"
  value       = yandex_lockbox_secret.ch_password.id
}

# ─────────────────────────────────────────────────────────────────
# Мониторинг
# ─────────────────────────────────────────────────────────────────

output "logging_group_id" {
  description = "ID Cloud Logging группы"
  value       = yandex_logging_group.main.id
}
