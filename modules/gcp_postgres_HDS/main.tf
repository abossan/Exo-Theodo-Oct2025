# Configuration principale du module PostgreSQL HDS
resource "google_sql_database_instance" "pg_instance" {
  name             = "pg-prod-instance"
  project          = var.project_id
  region           = var.region
  database_version = "POSTGRES_15"
  
  # 🔐 HDS  - Protection contre la suppression accidentelle
  deletion_protection = true

  # 🔐 HDS  - Chiffrement avec clé managée par le client (CMEK)
  disk_encryption_configuration {
    kms_key_name = google_kms_crypto_key.sql_crypto_key.id
  }

  settings {
    tier = var.db_tier

    # 🔐 HDS  - Sauvegardes automatiques et PITR
    backup_configuration {
      enabled                        = true
      start_time                     = "02:00"
      point_in_time_recovery_enabled = true
      transaction_log_retention_days = 7
    }

    # 🔐 HDS - Monitoring et maintenance
    maintenance_window {
      day  = 7
      hour = 3
    }

    disk_autoresize = true
    disk_size       = var.disk_size
    disk_type       = "PD_SSD"

    # 🔐 HDS  - Réseau privé uniquement
    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.vpc.id
      require_ssl     = true # 🔐 HDS  - SSL/TLS forcé
    }

    location_preference {
      zone = var.zone
    }

    # 🔐 HDS  - Audit et logging
    database_flags {
      name  = "log_connections"
      value = "on"
    }
    database_flags {
      name  = "log_disconnections"
      value = "on"
    }
    database_flags {
      name  = "log_statement"
      value = "ddl"
    }
  }

  # 🔐 HDS  - Dépendance explicite sur les ressources de sécurité
  depends_on = [
    google_kms_crypto_key_ring.sql_key_ring,
    google_project_iam_member.kms_sql_binding,
    google_secret_manager_secret_version.db_password
  ]
}

# 🔐 HDS  - Anneau de clés KMS pour le chiffrement
resource "google_kms_key_ring" "sql_key_ring" {
  name     = "sql-key-ring-${var.project_id}"
  location = var.kms_location
  project  = var.project_id
}

# 🔐 HDS  - Clé de chiffrement pour Cloud SQL
resource "google_kms_crypto_key" "sql_crypto_key" {
  name            = "sql-disk-encryption-key"
  key_ring        = google_kms_key_ring.sql_key_ring.id
  rotation_period = "2592000s" # 30 jours
  
  # 🔐 HDS P0 - Protection contre la suppression
  destruction_schedule_duration = "86400s" # 24 heures
  
  version_template {
    algorithm = "GOOGLE_SYMMETRIC_ENCRYPTION"
  }
}

# 🔐 HDS  - Autorisation pour Cloud SQL d'utiliser la clé KMS
resource "google_project_iam_member" "kms_sql_binding" {
  project = var.project_id
  role    = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member  = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-cloud-sql.iam.gserviceaccount.com"
}

# 🔐 HDS  - Réseau VPC sécurisé
resource "google_compute_network" "vpc" {
  name                    = "postgres-vpc-${var.project_id}"
  auto_create_subnetworks = false # 🔐 Contrôle manuel des sous-réseaux
  routing_mode            = "REGIONAL"
}

# 🔐 HDS  - Sous-réseau dédié
resource "google_compute_subnetwork" "private_subnet" {
  name          = "postgres-private-subnet"
  ip_cidr_range = "10.1.0.0/24"
  region        = var.region
  network       = google_compute_network.vpc.id
  
  # 🔐 HDS P- Accès privé uniquement
  private_ip_google_access = true
}

# Base de données principale
resource "google_sql_database" "db" {
  name     = var.db_name
  instance = google_sql_database_instance.pg_instance.name
}

# 🔐 HDS  - Utilisateur avec mot de passe depuis Secret Manager
resource "google_sql_user" "db_user" {
  name     = var.db_user
  instance = google_sql_database_instance.pg_instance.name
  password = data.google_secret_manager_secret_version.db_password.secret_data
}

# 🔐 HDS  - Configuration des logs d'audit
resource "google_project_iam_audit_config" "sql_audit" {
  project = var.project_id
  service = "cloudsql.googleapis.com"
  audit_log_config {
    log_type = "ADMIN_READ"
  }
  audit_log_config {
    log_type = "DATA_READ"
  }
  audit_log_config {
    log_type = "DATA_WRITE"
  }
}

# 🔐 HDS  - Bucket de stockage des logs d'audit
resource "google_storage_bucket" "audit_bucket" {
  name                        = "sql-audit-logs-${var.project_id}"
  location                    = var.audit_logs_location
  uniform_bucket_level_access = true
  force_destroy               = false

  # 🔐 HDS - Rétention des logs 90 jours minimum
  retention_policy {
    retention_period = 7776000 # 90 jours en secondes
  }

  # 🔐 HDS - Chiffrement des logs
  encryption {
    default_kms_key_name = google_kms_crypto_key.audit_crypto_key.id
  }
}

# 🔐 HDS  - Clé KMS dédiée pour les logs d'audit
resource "google_kms_crypto_key" "audit_crypto_key" {
  name            = "audit-logs-encryption-key"
  key_ring        = google_kms_key_ring.sql_key_ring.id
  rotation_period = "2592000s"
  
  version_template {
    algorithm = "GOOGLE_SYMMETRIC_ENCRYPTION"
  }
}

# 🔐 HDS  - Sink pour les logs Cloud SQL
resource "google_logging_project_sink" "sql_audit_sink" {
  name        = "sql-audit-logs-sink"
  destination = "storage.googleapis.com/${google_storage_bucket.audit_bucket.name}"
  filter      = "resource.type=cloudsql_database"
}

# 🔐 HDS - Sink pour les logs KMS
resource "google_logging_project_sink" "kms_audit_sink" {
  name        = "kms-audit-logs-sink"
  destination = "storage.googleapis.com/${google_storage_bucket.audit_bucket.name}"
  filter      = "resource.type=kms_keyring OR resource.type=kms_cryptokey"
}

# 🔐 HDS - Données du projet pour les comptes de service
data "google_project" "project" {
  project_id = var.project_id
}
