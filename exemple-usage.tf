module "postgres_prod" {
  source      = "./modules/gcp_postgres"
  project_id  = "exo-terraform"
  db_password = "MotDePasseTresFort123!"
}
