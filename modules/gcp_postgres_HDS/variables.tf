# Variables principales du module PostgreSQL HDS
variable "project_id" {
  description = "ID du projet GCP"
  type        = string
}

variable "region" {
  description = "Région du déploiement"
  type        = string
  default     = "europe-west1" # 🔐 HDS 
}

variable "zone" {
  description = "Zone de déploiement"
  type        = string
  default     = "europe-west1-b"
}

variable "db_tier" {
  description = "Type d'instance Cloud SQL"
  type        = string
  default     = "db-custom-1-3840" # 🔐 HDS - Tier adapté aux besoins production
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

# 🔐 HDS  - Suppression du mot de passe en variable sensible
# Le mot de passe est maintenant géré via Secret Manager

variable "disk_size" {
  description = "Taille du disque en Go"
  type        = number
  default     = 20
}

variable "kms_location" {
  description = "Localisation du Key Ring KMS"
  type        = string
  default     = "global"
}

variable "audit_logs_location" {
  description = "Localisation du bucket de logs d'audit"
  type        = string
  default     = "EU"
}

# 🔐 HDS  - Variable pour le secret ID
variable "db_password_secret_id" {
  description = "ID du secret dans Secret Manager contenant le mot de passe"
  type        = string
  default     = "db-password"
}