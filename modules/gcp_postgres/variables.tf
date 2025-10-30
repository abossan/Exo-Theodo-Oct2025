variable "project_id" {
  description = "ID du projet GCP"
  type        = string
}

variable "region" {
  description = "Région du déploiement"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "Zone de déploiement"
  type        = string
  default     = "us-central1-a"
}

variable "db_tier" {
  description = "Type d’instance Cloud SQL"
  type        = string
  default     = "db-f1-micro" # Gratuit dans le Free Tier
}

variable "db_name" {
  description = "Nom de la base de données"
  type        = string
  default     = "securedb"
}

variable "db_user" {
  description = "Nom de l'utilisateur principal"
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "Mot de passe PostgreSQL"
  type        = string
  sensitive   = true
}
