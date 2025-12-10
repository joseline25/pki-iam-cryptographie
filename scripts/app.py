from flask import Flask, url_for, session, redirect, render_template_string
from authlib.integrations.flask_client import OAuth
from werkzeug.middleware.proxy_fix import ProxyFix 
import os
import  warnings
import requests

warnings.filterwarnings('ignore', message='Unverified HTTPS request')

app = Flask(__name__)

# Lit les headers X-Forwarded-* de Nginx et force Flask à voir HTTPS
app.wsgi_app = ProxyFix(app.wsgi_app, x_proto=1, x_host=1)

app.secret_key = 'random_secret_key_for_cookie_signing'
app.config['SESSION_COOKIE_SECURE'] = True
app.config['SESSION_COOKIE_SAMESITE'] = 'None'

# === CONFIGURATION ZERO TRUST ===

# URL de Keycloak 
#KEYCLOAK_URL = "https://portal.securecorp.local:8443/realms/SecureCorp"
KEYCLOAK_URL = "http://192.168.56.10:8080/realms/SecureCorp"

# Configuration OAuth
oauth = OAuth(app)
oauth.register(
    name='securecorp',
    client_id='python-portal',
    client_secret='super-secret-python-key',
    
    # === DEFINITION MANUELLE DES ENDPOINTS (pour éviter l'erreur SSL) ===
    access_token_url=f'{KEYCLOAK_URL}/protocol/openid-connect/token',
    authorize_url=f'{KEYCLOAK_URL}/protocol/openid-connect/auth',
    userinfo_url=f'{KEYCLOAK_URL}/protocol/openid-connect/userinfo',
    jwks_uri=f'{KEYCLOAK_URL}/protocol/openid-connect/certs',
    
    # Options client :
    client_kwargs={
        'scope': 'openid email profile',
        
    }
)

@app.route('/')
def index():
    user = session.get('user')
    if user:
        # On affiche le nom de l'utilisateur récupéré du token
        username = user.get('preferred_username', 'Utilisateur')
        return f'''
        <div style="text-align: center; margin-top: 50px; font-family: sans-serif;">
            <h1 style="color: green;"> Accès Autorisé</h1>
            <h2>Bienvenue chez SecureCorp</h2>
            <p>Connecté en tant que : <strong>{username}</strong></p>
            <hr>
            <p>Token ID : {user.get('sub')}</p>
            <br>
            <a href="/logout" style="background: #d9534f; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px;">Se Déconnecter</a>
        </div>
        '''
    else:
        return '''
        <div style="text-align: center; margin-top: 50px; font-family: sans-serif;">
            <h1> Portail SecureCorp</h1>
            <p>Zone Sécurisée - Authentification Requise</p>
            <br>
            <a href="/login" style="background: #0275d8; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px;">Se connecter avec SSO</a>
        </div>
        '''

@app.route('/login')
def login():
    # on redirige l'utilisateur vers Keycloak pour le login
    # on précise l'URL de retour (callback)
    redirect_uri = url_for('auth_callback', _external=True, _scheme='https')
    return oauth.securecorp.authorize_redirect(redirect_uri)

@app.route('/oidc_callback')
def auth_callback():
    # Keycloak nous renvoie ici après le login
    try:
        token = oauth.securecorp.authorize_access_token()
        # on stocke les infos utilisateur dans la session Flask
        session['user'] = token['userinfo']
        return redirect('/')
    except Exception as e:
        return f"<h1>Erreur d'authentification</h1><p>{e}</p>"

@app.route('/logout')
def logout():
    session.pop('user', None)
    # URL de logout Keycloak pour fermer aussi la session là-bas
    logout_url = f"{KEYCLOAK_URL}/protocol/openid-connect/logout?post_logout_redirect_uri={url_for('index', _external=True)}"
    return redirect(logout_url)

if __name__ == '__main__':
    # Désactive la vérification HTTPS stricte pour OAuth ( uniquement pour le lab pas normal quoi)
    os.environ['OAUTHLIB_INSECURE_TRANSPORT'] = '1'
    # L'app écoute sur toutes les interfaces
    app.run(host='0.0.0.0', port=5000, debug=True)