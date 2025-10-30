output "db_instance_connection_name" {
  description = "Nom de connexion de l'instance"
  value       = google_sql_database_instance.pg_instance.connection_name
}

output "database_name" {
  description = "Nom de la base de données créée"
  value       = google_sql_database.db.name
}
