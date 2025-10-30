# 🔐 HDS  - Gestion des secrets via Secret Manager
resource "google_secret_manager_secret" "db_password" {
  secret_id = var.db_password_secret_id
  
  replication {
    automatic = true
  }

  # 🔐 HDS  - Rotation des secrets
  rotation {
    next_rotation_time = timeadd(timestamp(), "2160h") # 90 jours
    rotation_period    = "2160h" # 90 jours
  }

  # 🔐 HDS  - Protection contre la suppression
  lifecycle {
    prevent_destroy = true
  }
}

# 🔐 HDS  - Version initiale du secret
resource "google_secret_manager_secret_version" "db_password" {
  secret      = google_secret_manager_secret.db_password.id
  secret_data = var.initial_db_password
  
  # 🔐 HDS - Empêcher la destruction accidentelle
  lifecycle {
    prevent_destroy = false # Permettre la destruction pour les besoins Terraform
  }
}

# 🔐 HDS  - Accès en lecture pour Cloud SQL
data "google_secret_manager_secret_version" "db_password" {
  secret  = google_secret_manager_secret.db_password.id
  version = "latest"
  
  depends_on = [google_secret_manager_secret_version.db_password]
}

# 🔐 HDS - Variable pour le mot de passe initial
variable "initial_db_password" {
  description = "Mot de passe initial pour la base de données (sera stocké dans Secret Manager)"
  type        = string
  sensitive   = true
}