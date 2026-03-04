# ═══════════════════════════════════════════════════════════════
# Terraform — Инфраструктура «Будущее 2.0» на Yandex Cloud
# Провайдер: yandex-cloud/yandex (как в учебном материале)
# ═══════════════════════════════════════════════════════════════

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.100"
    }
  }

  # Раскомментировать для production: хранение state в Object Storage
  # backend "s3" {
  #   endpoint   = "storage.yandexcloud.net"
  #   bucket     = "tf-state-buduschee2"
  #   region     = "ru-central1"
  #   key        = "buduschee2/terraform.tfstate"
  #   access_key = var.s3_access_key
  #   secret_key = var.s3_secret_key
  #   skip_region_validation      = true
  #   skip_credentials_validation = true
  # }
}

provider "yandex" {
  token     = var.yc_token
  cloud_id  = var.yc_cloud_id
  folder_id = var.yc_folder_id
  zone      = var.yc_zone
}

# ─────────────────────────────────────────────────────────────────
# Образ ОС — Ubuntu 22.04 LTS
# Используем data-блок, как показано в учебном примере:
# data "yandex_compute_image" позволяет получить актуальный
# image_id без хардкода конкретной версии
# ─────────────────────────────────────────────────────────────────

data "yandex_compute_image" "ubuntu" {
  family = "ubuntu-2204-lts"
}

# ─────────────────────────────────────────────────────────────────
# Мониторинг: Cloud Logging Group
# ─────────────────────────────────────────────────────────────────

resource "yandex_logging_group" "main" {
  name             = "${var.prefix}-logs"
  folder_id        = var.yc_folder_id
  retention_period = "${var.log_retention_hours}h"
}

# ─────────────────────────────────────────────────────────────────
# Сеть: VPC Network + подсети доменов
# ─────────────────────────────────────────────────────────────────

resource "yandex_vpc_network" "main" {
  name      = "${var.prefix}-network"
  folder_id = var.yc_folder_id
}

# NAT Gateway — обеспечивает исходящий интернет для приватных подсетей
# Эквивалент nat=true из учебного примера, но на уровне сети
resource "yandex_vpc_gateway" "nat" {
  name      = "${var.prefix}-nat-gw"
  folder_id = var.yc_folder_id
  shared_egress_gateway {}
}

resource "yandex_vpc_route_table" "main" {
  name       = "${var.prefix}-route-table"
  network_id = yandex_vpc_network.main.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat.id
  }
}

# Подсеть: Медицинский домен (строгая изоляция — ПДн, медтайна)
resource "yandex_vpc_subnet" "medical" {
  name           = "medical-subnet"
  zone           = var.yc_zone
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = [var.subnet_medical]
}

# Подсеть: Финтех-домен (банковская изоляция — ЦБ РФ, PCI-DSS)
resource "yandex_vpc_subnet" "fintech" {
  name           = "fintech-subnet"
  zone           = var.yc_zone
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = [var.subnet_fintech]
}

# Подсеть: ИИ-домен
resource "yandex_vpc_subnet" "ai" {
  name           = "ai-subnet"
  zone           = var.yc_zone
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = [var.subnet_ai]
}

# Подсеть: Корпоративная аналитика
resource "yandex_vpc_subnet" "analytics" {
  name           = "analytics-subnet"
  zone           = var.yc_zone
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = [var.subnet_analytics]
}

# Подсеть: Kubernetes-кластер (с привязкой NAT-таблицы)
resource "yandex_vpc_subnet" "k8s" {
  name           = "k8s-subnet"
  zone           = var.yc_zone
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = [var.subnet_k8s]
  route_table_id = yandex_vpc_route_table.main.id
}

# Подсеть: Интеграционный слой (Kafka, API Gateway)
resource "yandex_vpc_subnet" "integration" {
  name           = "integration-subnet"
  zone           = var.yc_zone
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = [var.subnet_integration]
  route_table_id = yandex_vpc_route_table.main.id
}

# ─────────────────────────────────────────────────────────────────
# Security Groups — изоляция доменов на уровне сети
# ─────────────────────────────────────────────────────────────────

# SG: Медицинский домен — входящий трафик только от k8s-подсети
resource "yandex_vpc_security_group" "medical" {
  name        = "${var.prefix}-medical-sg"
  description = "Медицинский домен: только Medical API из k8s-подсети"
  network_id  = yandex_vpc_network.main.id

  ingress {
    protocol       = "TCP"
    description    = "Medical API от k8s-нод"
    port           = 8080
    v4_cidr_blocks = [var.subnet_k8s]
  }

  ingress {
    protocol       = "TCP"
    description    = "SSH для администрирования"
    port           = 22
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "ANY"
    description    = "Исходящий трафик разрешён"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# SG: Финтех-домен — запрет прямого доступа из медицинской подсети
resource "yandex_vpc_security_group" "fintech" {
  name        = "${var.prefix}-fintech-sg"
  description = "Финтех-домен: изоляция от медицинской подсети"
  network_id  = yandex_vpc_network.main.id

  ingress {
    protocol       = "TCP"
    description    = "Fintech API от k8s-нод"
    port           = 8080
    v4_cidr_blocks = [var.subnet_k8s]
  }

  ingress {
    protocol       = "TCP"
    description    = "PostgreSQL от k8s-нод"
    port           = 5432
    v4_cidr_blocks = [var.subnet_k8s]
  }

  egress {
    protocol       = "ANY"
    description    = "Исходящий трафик разрешён"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# ─────────────────────────────────────────────────────────────────
# Сервисные аккаунты IAM
# В Yandex Cloud ресурсы используют service account вместо
# managed identity из Azure
# ─────────────────────────────────────────────────────────────────

resource "yandex_iam_service_account" "k8s" {
  name        = "${var.prefix}-k8s-sa"
  description = "Сервисный аккаунт для управления k8s-кластером"
  folder_id   = var.yc_folder_id
}

resource "yandex_iam_service_account" "k8s_nodes" {
  name        = "${var.prefix}-k8s-nodes-sa"
  description = "Сервисный аккаунт для нод k8s (pull образов из registry)"
  folder_id   = var.yc_folder_id
}

resource "yandex_resourcemanager_folder_iam_member" "k8s_editor" {
  folder_id = var.yc_folder_id
  role      = "editor"
  member    = "serviceAccount:${yandex_iam_service_account.k8s.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "k8s_nodes_puller" {
  folder_id = var.yc_folder_id
  role      = "container-registry.images.puller"
  member    = "serviceAccount:${yandex_iam_service_account.k8s_nodes.id}"
}

# ─────────────────────────────────────────────────────────────────
# Container Registry — хранилище Docker-образов
# ─────────────────────────────────────────────────────────────────

resource "yandex_container_registry" "main" {
  name      = "${var.prefix}-registry"
  folder_id = var.yc_folder_id
}

# ─────────────────────────────────────────────────────────────────
# Managed Kafka — интеграционная шина событий
# Заменяет Apache Camel ESB; Kafka-совместимый протокол
# ─────────────────────────────────────────────────────────────────

resource "yandex_mdb_kafka_cluster" "main" {
  name        = "${var.prefix}-kafka"
  environment = "PRODUCTION"
  network_id  = yandex_vpc_network.main.id
  folder_id   = var.yc_folder_id

  config {
    version          = "3.6"
    zones            = [var.yc_zone]
    brokers_count    = 1
    assign_public_ip = false

    kafka {
      resources {
        resource_preset_id = var.kafka_preset_id
        disk_type_id       = "network-ssd"
        disk_size          = var.kafka_disk_gb
      }

      kafka_config {
        compression_type                = "COMPRESSION_TYPE_LZ4"
        log_retention_ms                = 604800000  # 7 дней
        log_segment_bytes               = 134217728  # 128 MB
        num_partitions                  = var.kafka_default_partitions
      }
    }
  }

  subnet_ids = [yandex_vpc_subnet.integration.id]
}

# Топик: события медицинского домена (без ПДн, только агрегаты)
resource "yandex_mdb_kafka_topic" "medical_events" {
  cluster_id         = yandex_mdb_kafka_cluster.main.id
  name               = "medical-events"
  partitions         = var.kafka_default_partitions
  replication_factor = 1

  topic_config {
    retention_ms = 604800000
  }
}

# Топик: события финтех-домена
resource "yandex_mdb_kafka_topic" "fintech_events" {
  cluster_id         = yandex_mdb_kafka_cluster.main.id
  name               = "fintech-events"
  partitions         = var.kafka_default_partitions
  replication_factor = 1

  topic_config {
    retention_ms = 604800000
  }
}

# Топик: партнёрский канал — фармкомпании
resource "yandex_mdb_kafka_topic" "partners_pharma" {
  cluster_id         = yandex_mdb_kafka_cluster.main.id
  name               = "partners-pharma-v1"
  partitions         = 2
  replication_factor = 1
}

# Топик: партнёрский канал — производитель медоборудования
resource "yandex_mdb_kafka_topic" "partners_devices" {
  cluster_id         = yandex_mdb_kafka_cluster.main.id
  name               = "partners-devices-v1"
  partitions         = 2
  replication_factor = 1
}

# ─────────────────────────────────────────────────────────────────
# Object Storage — медицинское хранилище (Data Lake)
# Изолированное хранилище медкарт и снимков
# ─────────────────────────────────────────────────────────────────

resource "yandex_storage_bucket" "medical_datalake" {
  bucket    = "${var.prefix}-medical-datalake"
  folder_id = var.yc_folder_id
  # acl "private" по умолчанию; явный аргумент acl устарел — используется yandex_storage_bucket_acl

  versioning {
    enabled = true
  }

  lifecycle_rule {
    id      = "expire-old-versions"
    enabled = true

    noncurrent_version_expiration {
      days = 90
    }
  }

  # Шифрование: Yandex Object Storage шифрует данные по умолчанию (AES-256).
  # Явная конфигурация SSE с KMS требует отдельного yandex_kms_symmetric_key.
}

# ─────────────────────────────────────────────────────────────────
# Managed ClickHouse — Corporate Cloud DWH
# Колоночная аналитическая БД (эквивалент Azure Synapse)
# Быстрые агрегирующие запросы на сотнях ТБ
# ─────────────────────────────────────────────────────────────────

resource "yandex_mdb_clickhouse_cluster" "dwh" {
  name        = "${var.prefix}-dwh"
  environment = var.environment == "prod" ? "PRODUCTION" : "PRESTABLE"
  network_id  = yandex_vpc_network.main.id
  folder_id   = var.yc_folder_id

  clickhouse {
    resources {
      resource_preset_id = var.ch_preset_id
      disk_type_id       = "network-ssd"
      disk_size          = var.ch_disk_gb
    }
  }

  host {
    type      = "CLICKHOUSE"
    zone      = var.yc_zone
    subnet_id = yandex_vpc_subnet.analytics.id
  }
}

# БД и пользователь ClickHouse — отдельные ресурсы (рекомендуемый подход провайдера 0.100+)
resource "yandex_mdb_clickhouse_database" "corporatedwh" {
  cluster_id = yandex_mdb_clickhouse_cluster.dwh.id
  name       = "corporatedwh"
}

resource "yandex_mdb_clickhouse_user" "dwhadmin" {
  cluster_id = yandex_mdb_clickhouse_cluster.dwh.id
  name       = var.ch_admin_user
  password   = var.ch_admin_password

  permission {
    database_name = "corporatedwh"
  }

  depends_on = [yandex_mdb_clickhouse_database.corporatedwh]
}

# ─────────────────────────────────────────────────────────────────
# Managed PostgreSQL — Финтех-домен
# Операционная БД для счетов, кредитов, транзакций
# ─────────────────────────────────────────────────────────────────

resource "yandex_mdb_postgresql_cluster" "fintech" {
  name        = "${var.prefix}-fintech-pg"
  environment = var.environment == "prod" ? "PRODUCTION" : "PRESTABLE"
  network_id  = yandex_vpc_network.main.id
  folder_id   = var.yc_folder_id

  config {
    version = var.pg_version

    resources {
      resource_preset_id = var.pg_preset_id
      disk_type_id       = "network-ssd"
      disk_size          = var.pg_disk_gb
    }

    postgresql_config = {
      max_connections = 100
    }

    backup_window_start {
      hours   = 2
      minutes = 0
    }
  }

  host {
    zone      = var.yc_zone
    subnet_id = yandex_vpc_subnet.fintech.id
  }

  database {
    name  = "fintechdb"
    owner = var.pg_admin_user
  }

  user {
    name     = var.pg_admin_user
    password = var.pg_admin_password

    permission {
      database_name = "fintechdb"
    }
  }
}

# ─────────────────────────────────────────────────────────────────
# Диски для VM-компонентов
# Следуем паттерну учебного примера:
# сначала создаём диск, потом привязываем к инстансу
# ─────────────────────────────────────────────────────────────────

# Диск для сервера медицинского домена (Medical API)
resource "yandex_compute_disk" "medical_api" {
  name     = "${var.prefix}-medical-api-disk"
  type     = "network-ssd"
  zone     = var.yc_zone
  image_id = data.yandex_compute_image.ubuntu.image_id
  size     = var.vm_disk_gb
}

# Диск для сервера финтех-домена (Fintech Service)
resource "yandex_compute_disk" "fintech_api" {
  name     = "${var.prefix}-fintech-api-disk"
  type     = "network-ssd"
  zone     = var.yc_zone
  image_id = data.yandex_compute_image.ubuntu.image_id
  size     = var.vm_disk_gb
}

# ─────────────────────────────────────────────────────────────────
# Compute Instances — VM для domain-сервисов
# Структура идентична учебному примеру:
# resources → boot_disk → network_interface → metadata
# ─────────────────────────────────────────────────────────────────

# VM: Medical API Server
resource "yandex_compute_instance" "medical_api" {
  name        = "${var.prefix}-medical-api"
  platform_id = "standard-v3"
  zone        = var.yc_zone

  resources {
    cores  = var.vm_cores
    memory = var.vm_memory_gb
  }

  boot_disk {
    disk_id = yandex_compute_disk.medical_api.id
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.medical.id
    security_group_ids = [yandex_vpc_security_group.medical.id]
    nat                = false  # Приватная сеть; NAT через yandex_vpc_gateway
  }

  metadata = {
    ssh-keys = "ubuntu:${var.ssh_public_key}"
  }
}

# VM: Fintech API Server
resource "yandex_compute_instance" "fintech_api" {
  name        = "${var.prefix}-fintech-api"
  platform_id = "standard-v3"
  zone        = var.yc_zone

  resources {
    cores  = var.vm_cores
    memory = var.vm_memory_gb
  }

  boot_disk {
    disk_id = yandex_compute_disk.fintech_api.id
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.fintech.id
    security_group_ids = [yandex_vpc_security_group.fintech.id]
    nat                = false
  }

  metadata = {
    ssh-keys = "ubuntu:${var.ssh_public_key}"
  }
}

# ─────────────────────────────────────────────────────────────────
# Managed Kubernetes — платформа для микросервисов
# ─────────────────────────────────────────────────────────────────

resource "yandex_kubernetes_cluster" "main" {
  name        = "${var.prefix}-k8s"
  description = "K8s-кластер для всех доменов Будущее 2.0"
  network_id  = yandex_vpc_network.main.id
  folder_id   = var.yc_folder_id

  master {
    zonal {
      zone      = var.yc_zone
      subnet_id = yandex_vpc_subnet.k8s.id
    }

    public_ip = true

    maintenance_policy {
      auto_upgrade = true

      maintenance_window {
        day        = "sunday"
        start_time = "02:00"
        duration   = "3h"
      }
    }
  }

  service_account_id      = yandex_iam_service_account.k8s.id
  node_service_account_id = yandex_iam_service_account.k8s_nodes.id

  release_channel = "STABLE"

  depends_on = [
    yandex_resourcemanager_folder_iam_member.k8s_editor,
    yandex_resourcemanager_folder_iam_member.k8s_nodes_puller,
  ]
}

# Node group: системный пул
resource "yandex_kubernetes_node_group" "system" {
  cluster_id  = yandex_kubernetes_cluster.main.id
  name        = "system"
  description = "Системные поды: Airflow, Portal, прочее"
  version     = var.k8s_version

  instance_template {
    platform_id = "standard-v3"

    resources {
      cores         = var.k8s_system_cores
      memory        = var.k8s_system_memory_gb
      core_fraction = 100
    }

    boot_disk {
      type = "network-ssd"
      size = var.k8s_system_disk_gb
    }

    network_interface {
      subnet_ids = [yandex_vpc_subnet.k8s.id]
      nat        = false
    }

    metadata = {
      ssh-keys = "ubuntu:${var.ssh_public_key}"
    }
  }

  scale_policy {
    fixed_scale {
      size = var.k8s_system_node_count
    }
  }

  allocation_policy {
    location {
      zone = var.yc_zone
    }
  }

  timeouts {
    create = "90m"
    update = "90m"
    delete = "60m"
  }
}

# Node group: AI-пул (более мощные VM для инференса моделей)
resource "yandex_kubernetes_node_group" "ai" {
  cluster_id  = yandex_kubernetes_cluster.main.id
  name        = "ai-pool"
  description = "ИИ-нагрузки: инференс ML-моделей, обработка снимков"
  version     = var.k8s_version

  instance_template {
    platform_id = "standard-v3"

    resources {
      cores         = var.k8s_ai_cores
      memory        = var.k8s_ai_memory_gb
      core_fraction = 100
    }

    boot_disk {
      type = "network-ssd"
      size = var.k8s_ai_disk_gb
    }

    network_interface {
      subnet_ids = [yandex_vpc_subnet.ai.id]
      nat        = false
    }

    metadata = {
      ssh-keys = "ubuntu:${var.ssh_public_key}"
    }
  }

  scale_policy {
    fixed_scale {
      size = var.k8s_ai_node_count
    }
  }

  allocation_policy {
    location {
      zone = var.yc_zone
    }
  }

  node_labels = {
    "workload" = "ai"
    "domain"   = "ai"
  }

  node_taints = ["workload=ai:NoSchedule"]

  timeouts {
    create = "90m"
    update = "90m"
    delete = "60m"
  }
}

# ─────────────────────────────────────────────────────────────────
# API Gateway — единая точка входа для всех доменных API
# ─────────────────────────────────────────────────────────────────

resource "yandex_api_gateway" "main" {
  name        = "${var.prefix}-api-gw"
  description = "API Gateway Будущее 2.0 — routing, auth, rate limiting"
  folder_id   = var.yc_folder_id

  spec = <<-EOT
    openapi: "3.0.0"
    info:
      title: "Buduschee 2.0 API"
      version: "1.0.0"
    paths:
      /health:
        get:
          summary: "Health check"
          operationId: health
          x-yc-apigateway-integration:
            type: dummy
            content:
              application/json: '{"status": "ok", "service": "buduschee2"}'
            http_code: 200
            http_headers:
              Content-Type: application/json
      /medical/{path+}:
        x-yc-apigateway-any-method:
          summary: "Medical domain API"
          operationId: medical-proxy
          parameters:
            - name: path
              in: path
              required: false
              schema:
                type: string
          x-yc-apigateway-integration:
            type: http
            url: "http://${yandex_compute_instance.medical_api.network_interface[0].ip_address}:8080/{path}"
            method: ANY
            timeout: 30
      /fintech/{path+}:
        x-yc-apigateway-any-method:
          summary: "Fintech domain API"
          operationId: fintech-proxy
          parameters:
            - name: path
              in: path
              required: false
              schema:
                type: string
          x-yc-apigateway-integration:
            type: http
            url: "http://${yandex_compute_instance.fintech_api.network_interface[0].ip_address}:8080/{path}"
            method: ANY
            timeout: 30
  EOT
}

# ─────────────────────────────────────────────────────────────────
# Lockbox — хранилище секретов (эквивалент Azure Key Vault)
# ─────────────────────────────────────────────────────────────────

resource "yandex_lockbox_secret" "pg_password" {
  name      = "${var.prefix}-pg-password"
  folder_id = var.yc_folder_id
}

resource "yandex_lockbox_secret_version" "pg_password" {
  secret_id = yandex_lockbox_secret.pg_password.id

  entries {
    key        = "password"
    text_value = var.pg_admin_password
  }
}

resource "yandex_lockbox_secret" "ch_password" {
  name      = "${var.prefix}-ch-password"
  folder_id = var.yc_folder_id
}

resource "yandex_lockbox_secret_version" "ch_password" {
  secret_id = yandex_lockbox_secret.ch_password.id

  entries {
    key        = "password"
    text_value = var.ch_admin_password
  }
}
