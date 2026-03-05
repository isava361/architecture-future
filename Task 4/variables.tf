# ═══════════════════════════════════════════════════════════════
# variables.tf — Переменные для инфраструктуры на Yandex Cloud
# ═══════════════════════════════════════════════════════════════

# ─────────────────────────────────────────────────────────────────
# Yandex Cloud — аутентификация и идентификация
# ─────────────────────────────────────────────────────────────────

variable "yc_token" {
  type        = string
  description = "OAuth-токен Yandex Cloud (yc iam create-token)"
  sensitive   = true
}

variable "yc_cloud_id" {
  type        = string
  description = "ID облака Yandex Cloud (yc config get cloud-id)"
}

variable "yc_folder_id" {
  type        = string
  description = "ID каталога (папки) в Yandex Cloud (yc config get folder-id)"
}

variable "yc_zone" {
  type        = string
  description = "Зона доступности Yandex Cloud"
  default     = "ru-central1-a"

  validation {
    condition     = contains(["ru-central1-a", "ru-central1-b", "ru-central1-c", "ru-central1-d"], var.yc_zone)
    error_message = "yc_zone должен быть одной из зон ru-central1."
  }
}

# ─────────────────────────────────────────────────────────────────
# Общее
# ─────────────────────────────────────────────────────────────────

variable "prefix" {
  type        = string
  description = "Короткий префикс для имён ресурсов (3–6 символов, строчные буквы и цифры)"
  default     = "bud2"

  validation {
    condition     = can(regex("^[a-z0-9]{2,6}$", var.prefix))
    error_message = "prefix должен содержать только строчные буквы и цифры, длина 2–6 символов."
  }
}

variable "environment" {
  type        = string
  description = "Окружение: dev, staging, prod"
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment должен быть одним из: dev, staging, prod."
  }
}

# ─────────────────────────────────────────────────────────────────
# Сетевые переменные
# ─────────────────────────────────────────────────────────────────

variable "subnet_medical" {
  type        = string
  description = "CIDR подсети медицинского домена"
  default     = "10.0.1.0/24"
}

variable "subnet_fintech" {
  type        = string
  description = "CIDR подсети финтех-домена"
  default     = "10.0.2.0/24"
}

variable "subnet_ai" {
  type        = string
  description = "CIDR подсети ИИ-домена"
  default     = "10.0.3.0/24"
}

variable "subnet_analytics" {
  type        = string
  description = "CIDR подсети корпоративной аналитики"
  default     = "10.0.4.0/24"
}

variable "subnet_k8s" {
  type        = string
  description = "CIDR подсети Kubernetes-кластера (/22 = 1024 адреса для нод)"
  default     = "10.0.8.0/22"
}

variable "subnet_integration" {
  type        = string
  description = "CIDR подсети интеграционного слоя (Kafka, API GW)"
  default     = "10.0.20.0/24"
}

# ─────────────────────────────────────────────────────────────────
# SSH-ключ для VM и k8s-нод
# ─────────────────────────────────────────────────────────────────

variable "ssh_public_key" {
  type        = string
  description = "Публичный SSH-ключ для доступа к VM (содержимое ~/.ssh/id_rsa.pub)"
}

# ─────────────────────────────────────────────────────────────────
# Compute Instances — VM для domain-сервисов
# ─────────────────────────────────────────────────────────────────

variable "vm_cores" {
  type        = number
  description = "Количество vCPU для domain VM (medical-api, fintech-api)"
  default     = 2
}

variable "vm_memory_gb" {
  type        = number
  description = "Объём RAM для domain VM в ГБ"
  default     = 4
}

variable "vm_disk_gb" {
  type        = number
  description = "Размер загрузочного диска domain VM в ГБ"
  default     = 15
}

# ─────────────────────────────────────────────────────────────────
# Managed Kafka
# ─────────────────────────────────────────────────────────────────

variable "kafka_preset_id" {
  type        = string
  description = "Пресет ресурсов брокера Kafka (s2.micro = 2 vCPU, 8 GB)"
  default     = "s2.micro"
}

variable "kafka_disk_gb" {
  type        = number
  description = "Объём диска Kafka-брокера в ГБ"
  default     = 20
}

variable "kafka_default_partitions" {
  type        = number
  description = "Количество партиций в топике по умолчанию (= параллелизм консьюмеров)"
  default     = 4
}

# ─────────────────────────────────────────────────────────────────
# Managed ClickHouse (Corporate Cloud DWH)
# ─────────────────────────────────────────────────────────────────

variable "ch_preset_id" {
  type        = string
  description = "Пресет ресурсов ClickHouse (s2.micro = dev, s2.medium = prod)"
  default     = "s2.micro"
}

variable "ch_disk_gb" {
  type        = number
  description = "Объём диска ClickHouse в ГБ"
  default     = 32
}

variable "ch_admin_user" {
  type        = string
  description = "Имя администратора ClickHouse DWH"
  default     = "dwhadmin"
}

variable "ch_admin_password" {
  type        = string
  description = "Пароль администратора ClickHouse (чувствительный)"
  sensitive   = true
}

# ─────────────────────────────────────────────────────────────────
# Managed PostgreSQL (Финтех-домен)
# ─────────────────────────────────────────────────────────────────

variable "pg_preset_id" {
  type        = string
  description = "Пресет ресурсов PostgreSQL (s2.micro = 2 vCPU, 8 GB RAM)"
  default     = "s2.micro"
}

variable "pg_disk_gb" {
  type        = number
  description = "Объём диска PostgreSQL в ГБ"
  default     = 16
}

variable "pg_version" {
  type        = string
  description = "Версия PostgreSQL"
  default     = "15"
}

variable "pg_admin_user" {
  type        = string
  description = "Имя администратора PostgreSQL"
  default     = "pgadmin"
}

variable "pg_admin_password" {
  type        = string
  description = "Пароль администратора PostgreSQL (чувствительный)"
  sensitive   = true
}

# ─────────────────────────────────────────────────────────────────
# Managed Kubernetes
# ─────────────────────────────────────────────────────────────────

variable "k8s_version" {
  type        = string
  description = "Версия Kubernetes (должна совпадать с версией мастера)"
  default     = "1.32"
}

variable "k8s_system_cores" {
  type        = number
  description = "vCPU на ноду системного пула k8s"
  default     = 4
}

variable "k8s_system_memory_gb" {
  type        = number
  description = "RAM на ноду системного пула k8s в ГБ"
  default     = 16
}

variable "k8s_system_disk_gb" {
  type        = number
  description = "Диск ноды системного пула в ГБ (dev: 30, prod: 128+)"
  default     = 30
}

variable "k8s_system_node_count" {
  type        = number
  description = "Количество нод в системном пуле k8s"
  default     = 2
}

variable "k8s_ai_cores" {
  type        = number
  description = "vCPU на ноду AI-пула k8s (больше для инференса моделей)"
  default     = 8
}

variable "k8s_ai_memory_gb" {
  type        = number
  description = "RAM на ноду AI-пула k8s в ГБ"
  default     = 32
}

variable "k8s_ai_disk_gb" {
  type        = number
  description = "Диск ноды AI-пула в ГБ (dev: 50, prod: 256+)"
  default     = 50
}

variable "k8s_ai_node_count" {
  type        = number
  description = "Количество нод в AI-пуле k8s"
  default     = 1
}

# ─────────────────────────────────────────────────────────────────
# Мониторинг
# ─────────────────────────────────────────────────────────────────

variable "log_retention_hours" {
  type        = number
  description = "Срок хранения логов в Cloud Logging (часов). 720 = 30 дней"
  default     = 720
}
