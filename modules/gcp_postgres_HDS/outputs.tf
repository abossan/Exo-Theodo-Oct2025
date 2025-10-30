output "db_instance_connection_name" {
  description = "Nom de connexion de l'instance"
  value       = google_sql_database_instance.pg_instance.connection_name
}

output "database_name" {
  description = "Nom de la base de données créée"
  value       = google_sql_database.db.name
}

# 🔐 HDS  - Outputs de sécurité
output "kms_key_ring_id" {
  description = "ID de l'anneau de clés KMS"
  value       = google_kms_key_ring.sql_key_ring.id
}

output "kms_crypto_key_id" {
  description = "ID de la clé de chiffrement"
  value       = google_kms_crypto_key.sql_crypto_key.id
}

output "private_ip_address" {
  description = "Adresse IP privée de l'instance"
  value       = google_sql_database_instance.pg_instance.private_ip_address
}

output "audit_bucket_name" {
  description = "Nom du bucket de stockage des logs d'audit"
  value       = google_storage_bucket.audit_bucket.name
}

# 🔐 HDS  - Informations de monitoring
output "instance_self_link" {
  description = "Self-link de l'instance pour le monitoring"
  value       = google_sql_database_instance.pg_instance.self_link
}