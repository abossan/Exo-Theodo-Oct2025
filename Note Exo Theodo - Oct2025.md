# Exercice pour Théodo - Module Terraform GCP HDS
**Antoine Bossan – 30 octobre 2025**

---

## 0 - Contexte

Écrire un module Terraform GCP qui provisionne une base de données de données sensibles prod ready (PostgreSQL, au choix).

**Objectifs :**
- Donner au moins un exemple d'utilisation du module
- Documenter le raisonnement derrière la conception du module (choix de variables, etc.)
- Mettre l'accent sur la qualité et les bonnes pratiques
- Documenter et justifier les pratiques choisies

---

## 1 - Introduction : Principales exigences HDS applicables

**Sources HDS :** https://esante.gouv.fr/produits-services/hds

### 1.1 Localisation & Souveraineté des données
- **Hébergement obligatoire dans l'EEE** : Utiliser les régions GCP européennes (ex: europe-west1 Belgique, europe-west3 Allemagne, europe-west9 France)
- **Transparence juridique** : Déclarer l'application potentielle du CLOUD Act américain sur GCP
- **Résidence des données** : Activer les contraintes d'organisation GCP pour limiter géographiquement les ressources

### 1.2 Chiffrement 
- **Chiffrement au repos** : Obligatoire pour toutes les données
- **Chiffrement en transit** : SSL/TLS obligatoire
- **Gestion des clés** : Support CMEK (Customer-Managed Encryption Keys)

### 1.3 Disponibilité & Continuité
- **RPO/RTO définis** : Objectifs de récupération documentés  (Recovery Point Objective)& (Recovery Time Objective)
- **Sauvegardes automatiques** : Minimum quotidiennes
- **PITR** : Point-In-Time Recovery activé
- **Plan de Reprise d'Activité (PRA)**

### 1.4 Contrôle d'accès & IAM
- **Principe du moindre privilège**
- **Authentification forte** : MFA obligatoire
- **Séparation des rôles**
- **Traçabilité complète**

### 1.5 Réseau & Isolation
- **Réseau privé** : Pas d'IP publique
- **Segmentation** : VPC dédiés
- **Pare-feu** : Rules strictes

### 1.6 Gestion des secrets
- **Coffre-fort sécurisé** pour les secrets
- **Rotation automatique** des credentials
- **État Terraform chiffré**

### 1.7 Audit & Traçabilité
- **Logs centralisés et protégés**
- **Rétention** : Minimum 1 an
- **Immutabilité des logs**

### 1.8 Gouvernance & Conformité
- **SMSI ISO 27001**
- **Analyse de risques régulière**
- **Contrats de sous-traitance conformes RGPD**

### 1.9 Exigences techniques spécifiques

**Monitoring & Alerting - Métriques essentielles :**
- Disponibilité > 99.9%
- Latence des requêtes
- Espace disque
- Connexions actives
- Tentatives d'accès échouées

**Backup & Recovery - Stratégie 3-2-1 :**
- 3 copies des données
- 2 supports différents
- 1 copie hors-site (autre région)

---

## 2 - Approche de l'exercice

### 2.1 Choix architecture : Docker vs Service Manager

**Écartement des solutions alternatives :**

- **AlloyDB for PostgreSQL** : "Coût prohibitif" et "Surpuissant et trop cher pour mon use case"
- **Bare Metal Solution** : Hors GCP et coût prohibitif (5,000€/mois MINIMUM vs 50€ Cloud SQL)


**Comparatif des solutions :**

| Critère | Cloud SQL (HDS) | GKE + PostgreSQL autogéré |
|---------|-----------------|---------------------------|
| Conformité HDS | ✅ Native (certifiée HDS en europe-west9) | ⚠️ Possible mais complexe |
| Maintenance | ✅ Gérée par Google | ❌ À votre charge |
| Flexibilité | ❌ Limitée | ✅ Totale |


### 2.2 Stratégie pour répondre à l'exercice

**Démarche progressive :**
1. **Base simplifiée** pour vérifier les accès depuis mon poste de Dev : modules/gcp_postgres 

2. **Enrichissement** avec les exigences spécifiques détaillées :modules/gcp_postgres_HDS 

**Pour l'exercice :** Le projet GCP  s'appelle **Exo-Theodo** (*peut apparaître en dur dans la documentation)

**Version simple "PROD Ready" renforcée par :**
- IP privée uniquement
- CMEK activation + Rotation
- Backups automatiques
- SSL/TLS forcé
- Audit logs complets
- Secret Manager
- PITR activation
- VPC Service Controls
- IAM authentication
- Monitoring complet
- Gouvernance

**Pour être exhaustif, il faudrait également :**
- HA configuration
- Cross-region backups
- DLP scanning (Data Loss Prevention)
- Penetration testing
- Plan documenté et testé Disaster Recovery
- Multi-cloud backup
- ML anomaly detection
- SOAR integration
- Chaos engineering
- Advanced forensics

---

## 3 - Mode opératoire

### 3.1 Pré-requis

# Installer Terraform
sudo apt update && sudo apt install -y terraform

# Installer et configurer le SDK GCP
gcloud auth login
gcloud config set project exo-terraform


## 3.2 Activer les services nécessaires

gcloud services enable sqladmin.googleapis.com  
gcloud services enable compute.googleapis.com  
gcloud services enable cloudkms.googleapis.com  
gcloud services enable secretmanager.googleapis.com  

## 3.3 Création de la clé KMS

Créer un keyring :  
gcloud kms keyrings create my-key-ring --location=global  

Créer une clé KMS pour le chiffrement :  
gcloud kms keys create my-key --location=global --keyring=my-key-ring --purpose=encryption  

## 3.4 Création d'un secret dans Google Secret Manager

Créer un secret avec un mot de passe sécurisé :  
echo -n "MotDePasseTresFort123!" | gcloud secrets create db_password --data-file=-  

## 3.5 Création du Buckets pour les fichiers terraform r


export PROJECT_ID="mon-projet-gcp"
export TFSTATE_BUCKET="${PROJECT_ID}-tfstate"
export TFSTATE_LOCATION="europe-west1" 

gcloud storage buckets create gs://${TFSTATE_BUCKET} \
  --project=${PROJECT_ID} \
  --location=${TFSTATE_LOCATION} \
  --uniform-bucket-level-access \
  --versioning \
  --public-access-prevention

--uniform-bucket-level-access : simplifie la gestion IAM (obligatoire dans beaucoup d’orgas).

--versioning : garde un historique des versions du terraform.tfstate → indispensable pour restaurer en cas d’erreur.

--public-access-prevention : empêche toute exposition publique accidentelle.


## 3.6 Déploiement avec Terraform

Initialiser Terraform :  
terraform init  

Appliquer la configuration Terraform :  
terraform apply -auto-approve  

Supprimer l'infrastructure Terraform :  
terraform destroy -auto-approve  

## 4 - Remarques importantes

### 4.1 Sécurité des fichiers Terraform

- Les fichiers .tf ont été mis à jour pour une infrastructure HDS  
- Commentaires ajoutés dans les .tf pour échanges autoporteurs  
- L'espace de stockage Terraform contenant les fichiers d'état (state files) doit être sécurisé dans un backend chiffré avec contrôle d'accès strict  

### 4.2 Bonnes pratiques de sécurité

- Vérifier que le mot de passe est sécurisé et respecte les exigences client  
- Les clés KMS et secrets doivent être gérés avec soin pour éviter toute fuite  
- terraform destroy supprimera tous les objets créés par la configuration Terraform  

### 4.3 Gestion des logs avec Sinks

Analogie : Un évier (sink) avec plusieurs robinets :  

- Robinet 1 → Logs Cloud SQL  
- Robinet 2 → Logs KMS  
- Robinet 3 → Logs réseau  

Le sink est le système de tuyauterie qui dirige l'eau (les logs) vers le bon réservoir (destination)  

Points importants :  

- Les Sinks ne suppriment pas les logs originaux de Cloud Logging  
- Ils créent une copie dans la destination spécifiée  
- Fonctionnent en temps réel (quasi-instantané)  
- Nécessitent des permissions IAM pour écrire dans la destination  

### 4.4 Audit et conformité IAM

Audit Terraform :  
gcloud asset inventory list --content-type=iam-policy --filter='bindings.role:roles/owner' --project=$PROJECT_ID  

Mettre en place des rôles IAM minimaux :  
Le principe de base : "Least privilege" — Donner uniquement les droits nécessaires à chaque service.  

| Entité | Rôle minimal | Justification |
|--------|--------------|---------------|
| Service Terraform | roles/editor ou combinaison fine | Créer les ressources |
| Service Account Cloud SQL | roles/cloudkms.cryptoKeyEncrypterDecrypter | Chiffrement CMEK |
| Développeurs | roles/viewer | Lecture seule du projet |
| Auditeur sécurité | roles/logging.viewer + roles/logging.privateLogViewer | Accès complet aux logs |
| Compte applicatif (DB) | roles/cloudsql.client | Connexion SQL uniquement |

## 5 - Gouvernance, audit et documentation

### 5.1 Gouvernance et conformité HDS

**Cadrage réglementaire :**  

- Matrice RACI HDS : Définir clairement les responsabilités (Responsible, Accountable, Consulted, Informed)  
- Désignation du responsable de traitement : Conformément à l'article 26 du RGPD et aux exigences HDS  

**Documentation d'exploitation certifiée :**  

- Procédures de sauvegardes : Planification, exécution et vérification avec traçabilité complète  
- Protocole de restaurations : Procédure d'urgence testée trimestriellement  
- Gestion des accès d'urgence : Double authentification avec journalisation des accès  
- Cycle de vie des secrets : Rotation automatique et révocation immédiate  

**Monitoring HDS renforcé :**  

Tableaux de bord Cloud Monitoring dédiés :  

- Performance SQL : latence des requêtes, temps de réponse, connexions simultanées  
- Sécurité : erreurs d'authentification, tentatives de connexion suspectes  
- Chiffrement : opérations KMS, statut des clés, échecs de déchiffrement  
- Conformité : quotas d'utilisation, dépassements de seuils  

Système d'alertes critiques :  

- 🔴 Suppression d'instance SQL (niveau urgence)  
- 🔴 Échec de rotation KMS (niveau critique)  
- 🔴 Accès non autorisé IAM (niveau sécurité)  
- 🟡 Modification de configuration (niveau avertissement)  

### 5.2 Surveillance des journaux avec Cloud Monitoring / SIEM

- Centralisation des traces d'audit : Agrégation des logs Cloud SQL, KMS, IAM dans un SIEM dédié santé  (Blumira , IBM QRadar ... ) 
- Conservation 3 ans des journaux d'accès aux données sensibles  
- Détection automatique des comportements anormaux  

**Plan de réponse aux incidents :**  

- Révocation d'urgence CMEK : Procédure de blocage immédiat en cas de compromission  
- Isolation forensique : Préservation des preuves pour investigation  ("mise de côté” le système compromis
- Notification CNIL : Processus de déclaration sous 72h si nécessaire  

### 5.3 Documentation de conformité HDS

**Preuve de maîtrise opérationnelle :**  

- Scénarios de résilience testés : PRA/PCA validés annuellement  
- Registre des incidents : Analyse root-cause et mesures correctives  
- Audits de sécurité : Contrôles internes et externes biannuels  
- Preuve de formation : Habilitations et sensibilisation du personnel  

**Documentation "prod ready santé" :**  

- Certification de la chaîne de traitement HDS  
- Preuves de chiffrement bout-en-bout  
- Traçabilité complète des accès et modifications  
- Procédures de purge sécurisée des données  

*Document avec correction d'ortigographe lié à  l'assistance Claude (version entreprise) garantissant la non-réutilisation des données pour l'entraînement.*  
