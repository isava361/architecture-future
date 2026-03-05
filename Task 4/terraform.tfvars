# ═══════════════════════════════════════════════════════════════
# terraform.tfvars — значения переменных для окружения DEV
# Провайдер: Yandex Cloud
# ───────────────────────────────────────────────────────────────
# ВНИМАНИЕ: не коммитить в git с реальными токенами и паролями!
# Для CI/CD использовать переменные окружения:
#   export TF_VAR_yc_token="..."
#   export TF_VAR_pg_admin_password="..."
#   export TF_VAR_ch_admin_password="..."
# ═══════════════════════════════════════════════════════════════

# ─────────────────────────────────────────────────────────────────
# Yandex Cloud — аутентификация
# Получить значения:
#   yc iam create-token           → yc_token
#   yc config get cloud-id        → yc_cloud_id
#   yc config get folder-id       → yc_folder_id
# ─────────────────────────────────────────────────────────────────
yc_token     = "REPLACE_WITH_YC_TOKEN"          # yc iam create-token
yc_cloud_id  = "REPLACE_WITH_CLOUD_ID"          # yc config get cloud-id
yc_folder_id = "REPLACE_WITH_FOLDER_ID"         # yc config get folder-id
yc_zone      = "ru-central1-a"

# ─────────────────────────────────────────────────────────────────
# Общее
# ─────────────────────────────────────────────────────────────────
prefix      = "bud2"
environment = "dev"

# ─────────────────────────────────────────────────────────────────
# SSH-ключ (содержимое публичного ключа ~/.ssh/id_rsa.pub)
# ─────────────────────────────────────────────────────────────────
ssh_public_key = "REPLACE_WITH_SSH_PUBLIC_KEY"

# ─────────────────────────────────────────────────────────────────
# Сеть
# ─────────────────────────────────────────────────────────────────
subnet_medical     = "10.0.1.0/24"
subnet_fintech     = "10.0.2.0/24"
subnet_ai          = "10.0.3.0/24"
subnet_analytics   = "10.0.4.0/24"
subnet_k8s         = "10.0.8.0/22"
subnet_integration = "10.0.20.0/24"

# ─────────────────────────────────────────────────────────────────
# Compute Instances (domain VM)
# Dev: минимальные ресурсы — 2 vCPU, 4 GB RAM, 15 GB SSD
# ─────────────────────────────────────────────────────────────────
vm_cores     = 2
vm_memory_gb = 4
vm_disk_gb   = 15

# ─────────────────────────────────────────────────────────────────
# Managed Kafka
# Dev: s2.micro (2 vCPU, 8 GB), 20 GB SSD, 4 партиции
# Prod: s2.medium или выше
# ─────────────────────────────────────────────────────────────────
kafka_preset_id         = "s2.micro"
kafka_disk_gb           = 20
kafka_default_partitions = 4

# ─────────────────────────────────────────────────────────────────
# ClickHouse (Corporate DWH)
# Dev: s2.micro (2 vCPU, 8 GB), 32 GB SSD
# Prod: s2.medium+ c масштабированием шардов
# ─────────────────────────────────────────────────────────────────
ch_preset_id      = "s2.micro"
ch_disk_gb        = 32
ch_admin_user     = "dwhadmin"
ch_admin_password = "REPLACE_ME_ClickHouse#2026!"  # Заменить перед применением

# ─────────────────────────────────────────────────────────────────
# PostgreSQL (Финтех-домен)
# Dev: s2.micro (2 vCPU, 8 GB), 16 GB SSD, PostgreSQL 15
# Prod: s2.medium с Multi-AZ репликацией
# ─────────────────────────────────────────────────────────────────
pg_preset_id      = "s2.micro"
pg_disk_gb        = 16
pg_version        = "15"
pg_admin_user     = "pgadmin"
pg_admin_password = "REPLACE_ME_PgAdmin#2026!"     # Заменить перед применением

# ─────────────────────────────────────────────────────────────────
# Managed Kubernetes
# Dev: 2 системные ноды (4 vCPU, 16 GB), 1 AI-нода (8 vCPU, 32 GB)
# Prod: 3+ системных нод, 2+ AI-нод
# ─────────────────────────────────────────────────────────────────
k8s_version           = "1.32"

k8s_system_cores      = 4
k8s_system_memory_gb  = 16
k8s_system_disk_gb    = 30
k8s_system_node_count = 2

k8s_ai_cores          = 8
k8s_ai_memory_gb      = 32
k8s_ai_disk_gb        = 50
k8s_ai_node_count     = 1

# ─────────────────────────────────────────────────────────────────
# Мониторинг
# 720 часов = 30 дней
# ─────────────────────────────────────────────────────────────────
log_retention_hours = 720
