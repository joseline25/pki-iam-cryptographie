#!/bin/bash
# ==========================================
# Script d'Initialisation Vault (PKI + DB)
# VM : srv-sec-core
# ==========================================

export VAULT_ADDR='http://127.0.0.1:8200'
export VAULT_TOKEN='root'

echo ">>> 1. Configuration de la PKI (Certificats)..."
vault secrets enable pki
vault secrets tune -max-lease-ttl=87600h pki
vault write pki/root/generate/internal common_name="SecureCorp Root CA" ttl=87600h

# Création de l'autorité intermédiaire (simplifiée pour le script)
vault secrets enable -path=pki_int pki
vault secrets tune -max-lease-ttl=43800h pki_int
# ... (Logique de signature CSR omise pour brièveté, mais à inclure en prod) ...

# Création du rôle pour Nginx
vault write pki_int/roles/securecorp-dot-local \
    allowed_domains="securecorp.local" \
    allow_subdomains=true \
    max_ttl="72h"

echo ">>> 2. Configuration DB (PostgreSQL)..."
vault secrets enable database
vault write database/config/postgresql \
    plugin_name=postgresql-database-plugin \
    allowed_roles="keycloak-role" \
    connection_url="postgresql://{{username}}:{{password}}@localhost:5432/keycloak" \
    username="vault" \
    password="vault-root-password"

vault write database/roles/keycloak-role \
    db_name=postgresql \
    creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' SUPERUSER; GRANT ALL PRIVILEGES ON DATABASE keycloak TO \"{{name}}\";" \
    default_ttl="1h" \
    max_ttl="24h"

echo ">>> Vault est configuré !"