# Exemple d'utilisation du module PostgreSQL HDS
module "postgres_hds" {
  source = "./modules/gcp_postgres_HDS"
  
  project_id          = "exo-terraform"
  region              = "europe-west1"
  zone                = "europe-west1-b"
  
  # 🔐 HDS - Configuration de sécurité
  db_tier              = "db-custom-2-7680"  #nstance PostgreSQL avec 2 CPU virtuels et 7,5 Go de RAM.
  disk_size            = 50
  kms_location         = "europe-west1"
  audit_logs_location  = "EU"
  
  # 🔐 HDS - Secrets managés
  db_password_secret_id = "prod-db-password"
  initial_db_password   = "MotDePasseTresFort123!" # À remplacer par une valeur sécurisée
  
  # 🔐 HDS - Configuration base de données
  db_name = "hds_database"
  db_user = "hds_admin"
}

# 🔐 HDS - Outputs pour le monitoring
output "postgres_private_ip" {
  value = module.postgres_hds.private_ip_address
}

output "kms_key_info" {
  value = module.postgres_hds.kms_crypto_key_id
}

output "audit_logs_bucket" {
  value = module.postgres_hds.audit_bucket_name
}
