resource "google_sql_database_instance" "pg_instance" {
  name             = "pg-prod-instance"
  project          = var.project_id
  region           = var.region
  database_version = "POSTGRES_15"
  deletion_protection = false

  settings {
    tier = var.db_tier

    backup_configuration {
      enabled                        = true
      point_in_time_recovery_enabled = true
    }

    disk_autoresize = true
    disk_size       = 10
    disk_type       = "PD_SSD"

    ip_configuration {
   #   ipv4_enabled    = false
   #   private_network = google_compute_network.vpc.id
       ipv4_enabled = true
      }

    location_preference {
      zone = var.zone
    }
  }
}

# Réseau privé basique
resource "google_compute_network" "vpc" {
  name                    = "postgres-vpc"
  auto_create_subnetworks = true
}

# Base de données principale
resource "google_sql_database" "db" {
  name     = var.db_name
  instance = google_sql_database_instance.pg_instance.name
}

# Utilisateur admin
resource "google_sql_user" "db_user" {
  name     = var.db_user
  instance = google_sql_database_instance.pg_instance.name
  password = var.db_password
}
