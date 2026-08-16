#!/usr/bin/env bash
# =============================================================================
#  dev-keycloak-uris.sh — agrega los puertos del servidor dev a los clientes
#  de Keycloak de una plataforma.
#
#  Los clientes que importa sigic_install.sh apuntan a ${NGINX_BASE_URL}/admin/
#  y /app/ (frontends dockerizados). En dev local Nuxt corre en localhost:PUERTO,
#  así que Keycloak rechaza el callback con "Invalid parameter: redirect_uri".
#  Este script agrega esas URIs sin tocar las de producción.
#
#  Uso:
#    scripts/dev-keycloak-uris.sh <plataforma> [ambiente] [puerto_admin] [puerto_app]
#
#  Ejemplo:
#    scripts/dev-keycloak-uris.sh sedema local 3021 3022
# =============================================================================
set -euo pipefail

BUNDLE=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$BUNDLE"

PLATFORM=${1:?Uso: scripts/dev-keycloak-uris.sh <plataforma> [ambiente] [puerto_admin] [puerto_app]}
ENVNAME=${2:-local}
PROJECT="${PLATFORM}-${ENVNAME}"
PLATFORM_JSON="platforms/$PLATFORM/platform.json"

json_get() {
  python3 -c "
import json,sys
try:
    d=json.load(open(sys.argv[1]))
    for k in sys.argv[2].split('.'):
        d=d[k]
    print(d)
except Exception:
    print('')
" "$1" "$2"
}

ADMIN_PORT=${3:-$(json_get "$PLATFORM_JSON" ports.frontend_admin)}
APP_PORT=${4:-$(json_get "$PLATFORM_JSON" ports.frontend_app)}
ADMIN_PORT=${ADMIN_PORT:-3001}
APP_PORT=${APP_PORT:-3002}

ENV_FILE=".env.${PROJECT}"
[ -f "$ENV_FILE" ] || { echo "❌ No existe $ENV_FILE — corré primero: SIGIC_DEV=1 ./sigic_install.sh $PLATFORM $ENVNAME"; exit 1; }

env_get() { grep -m1 "^$1=" "$ENV_FILE" | cut -d= -f2-; }

BASE=$(env_get NGINX_BASE_URL)
ISSUER=$(env_get SOCIALACCOUNT_OIDC_ID_TOKEN_ISSUER)
REALM=${ISSUER##*/realms/}; REALM=${REALM%%/*}
ADMIN_CID=$(env_get ADMIN_KEYCLOAK_CLIENT_ID)
APP_CID=$(env_get APP_KEYCLOAK_CLIENT_ID)

KC_CONTAINER="keycloak4${PROJECT}"
KC_USER=${KC_ADMIN_USER:-kadmin}
KC_PASS=${KC_ADMIN_PASS:-kadmin}

docker inspect "$KC_CONTAINER" > /dev/null 2>&1 || { echo "❌ No existe el contenedor $KC_CONTAINER"; exit 1; }

kc() { docker exec "$KC_CONTAINER" /opt/keycloak/bin/kcadm.sh "$@"; }

echo "🔐 Realm: $REALM | Base: $BASE"

kc config credentials \
  --server http://localhost:8080/iam \
  --realm master \
  --user "$KC_USER" \
  --password "$KC_PASS" \
  --client admin-cli > /dev/null

add_dev_uris() { # add_dev_uris <clientId> <puerto> <subpath>
  local client=$1 port=$2 subpath=$3 cid
  cid=$(kc get clients -r "$REALM" -q clientId="$client" --fields id --format csv 2>/dev/null | tail -n1 | tr -d '"\r')
  if [ -z "$cid" ]; then
    echo "⚠️  Cliente $client no encontrado en el realm $REALM — saltando"
    return 0
  fi
  kc update "clients/$cid" -r "$REALM" \
    -s "redirectUris=[\"${BASE}${subpath}api/auth/callback/keycloak\",\"${BASE}${subpath}*\",\"http://localhost:${port}/api/auth/callback/keycloak\",\"http://localhost:${port}/*\"]" \
    -s 'webOrigins=["+"]' > /dev/null
  echo "✅ $client → http://localhost:${port}/* (además de ${BASE}${subpath}*)"
}

add_dev_uris "$ADMIN_CID" "$ADMIN_PORT" "/admin/"
add_dev_uris "$APP_CID"   "$APP_PORT"   "/app/"

echo "🎉 Redirect URIs de desarrollo listas"
