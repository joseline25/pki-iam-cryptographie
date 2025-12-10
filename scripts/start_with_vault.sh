#!/bin/bash

# 1. On s'authentifie à Vault (Ici le fait  avec le root token pour le lab, 
# en vrai on utiliserait 'AppRole' ou 'Kubernetes Auth')
export VAULT_ADDR='http://127.0.0.1:8200'
export VAULT_TOKEN='root'

echo ">>> Demande de credentials DB à Vault..."
SECRET_JSON=$(vault read -format=json database/creds/keycloak-role)

# 2. On extrait user/pass avec jq
DB_USER=$(echo $SECRET_JSON | jq -r .data.username)
DB_PASS=$(echo $SECRET_JSON | jq -r .data.password)

echo ">>> Credentials obtenus ! User: $DB_USER"

# 3. On injecte les variables d'environnement pour Keycloak
export KC_DB=postgres
export KC_DB_URL=jdbc:postgresql://localhost:5432/keycloak
export KC_DB_USERNAME=$DB_USER
export KC_DB_PASSWORD=$DB_PASS

# Variables Admin initiales (A supprimer après le 1er boot en prod)
#export KC_BOOTSTRAP_ADMIN_USERNAME=admin
#export KC_BOOTSTRAP_ADMIN_PASSWORD=admin

# premier boot
export KEYCLOAK_ADMIN=admin
export KEYCLOAK_ADMIN_PASSWORD=admin

# 4. On lance Keycloak
# proxy=edge car on aura Nginx devant plus tard
exec /opt/keycloak/bin/kc.sh start --proxy=edge --hostname=portal.securecorp.local:8443 --http-enabled=true --http-host=0.0.0.0
