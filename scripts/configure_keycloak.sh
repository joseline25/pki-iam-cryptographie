#!/bin/bash
# ==========================================
# Script de Configuration Keycloak
# VM : srv-sec-core
# ==========================================

# Authentification Admin
cd /opt/keycloak/bin/
./kcadm.sh config credentials --server http://localhost:8080 --realm master --user admin --password admin

echo ">>> Création du Realm SecureCorp..."
./kcadm.sh create realms -s realm=SecureCorp -s enabled=true

echo ">>> Création du Client Python..."
./kcadm.sh create clients -r SecureCorp -s clientId=python-portal \
    -s enabled=true \
    -s clientAuthenticatorType=client-secret \
    -s secret=TON_CLIENT_SECRET_ICI \
    -s "redirectUris=[\"https://portal.securecorp.local:8443/oidc_callback\"]" \
    -s standardFlowEnabled=true

echo ">>> Création de l'utilisateur Employé..."
./kcadm.sh create users -r SecureCorp -s username=employe1 -s enabled=true \
    -s email=employe1@securecorp.local -s firstName=Alfred -s lastName=Secure -s emailVerified=true
./kcadm.sh set-password -r SecureCorp --username employe1 --new-password password

echo ">>> Activation MFA..."
USER_ID=$(./kcadm.sh get users -r SecureCorp -q username=employe1 --fields id --format csv --noquotes)
./kcadm.sh update users/$USER_ID -r SecureCorp -s 'requiredActions=["CONFIGURE_TOTP"]'

echo ">>> Keycloak est prêt !"