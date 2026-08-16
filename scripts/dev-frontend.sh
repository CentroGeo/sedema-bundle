#!/usr/bin/env bash
# =============================================================================
#  dev-frontend.sh — Nuxt en modo dev con overlays de plataforma y hot reload
#
#  Replica en local lo que hace el Dockerfile del frontend:
#
#      COPY frontend/ .
#      COPY platforms/${PLATFORM_NAME}/overrides/frontend/ .
#
#  ...pero manteniendo `nuxt dev`: los archivos del overlay se copian dentro de
#  frontend/ y se sincronizan en caliente en ambos sentidos mientras el servidor
#  corre, de modo que Vite/Nuxt los ve como archivos normales del proyecto y el
#  HMR funciona igual que con el código base.
#
#  Al salir (Ctrl-C) el árbol de frontend/ se deja limpio: los archivos nuevos
#  se borran y los archivos base sobreescritos se restauran con git checkout.
#  Cualquier edición hecha dentro de frontend/ sobre un archivo del overlay se
#  guarda antes en platforms/<plataforma>/overrides/frontend/.
#
#  Uso:
#    scripts/dev-frontend.sh <plataforma> [admin|app] [opciones]
#
#  Opciones:
#    --env <nombre>   Ambiente del bundle a leer (default: local → .env.<plat>-local)
#    --port <n>       Puerto del servidor dev (default: platform.json → ports)
#    --regen-env      Regenera el .env del frontend aunque ya exista
#    --no-watch       Aplica el overlay una vez y no sincroniza en caliente
#    --keep           No restaura frontend/ al salir (deja el overlay aplicado)
#    --restore        Solo restaura frontend/ y sale (limpieza tras un crash)
#
#  Ejemplos:
#    scripts/dev-frontend.sh sedema admin
#    scripts/dev-frontend.sh conafor app --port 3012
#    scripts/dev-frontend.sh sedema admin --restore
# =============================================================================
set -euo pipefail

BUNDLE=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
FRONT="$BUNDLE/frontend"

PLATFORM=""
TARGET="admin"
ENVNAME="local"
PORT=""
REGEN_ENV=0
WATCH=1
KEEP=0
RESTORE_ONLY=0

usage() { sed -n '2,40p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 1; }

# ---------------------------------------------------------------- argumentos
[ $# -ge 1 ] || usage
PLATFORM=$1; shift
if [ $# -gt 0 ] && [[ "$1" != --* ]]; then TARGET=$1; shift; fi

while [ $# -gt 0 ]; do
  case "$1" in
    --env)        ENVNAME=$2; shift 2 ;;
    --port)       PORT=$2; shift 2 ;;
    --regen-env)  REGEN_ENV=1; shift ;;
    --no-watch)   WATCH=0; shift ;;
    --keep)       KEEP=1; shift ;;
    --restore)    RESTORE_ONLY=1; shift ;;
    -h|--help)    usage ;;
    *) echo "Opción desconocida: $1"; usage ;;
  esac
done

case "$TARGET" in
  admin|app) ;;
  *) echo "❌ El target debe ser 'admin' o 'app' (recibido: $TARGET)"; exit 1 ;;
esac

PLATFORM_DIR="$BUNDLE/platforms/$PLATFORM"
OVERLAY="$PLATFORM_DIR/overrides/frontend"
PLATFORM_JSON="$PLATFORM_DIR/platform.json"

[ -d "$PLATFORM_DIR" ] || { echo "❌ No existe la plataforma: $PLATFORM_DIR"; exit 1; }
mkdir -p "$OVERLAY"

# Nuxt toma un lock por directorio de proyecto: dos `nuxt dev` sobre el mismo
# frontend/ no coexisten (el segundo muere con "Another Nuxt dev is already
# running" y su puerto queda muerto). Además compartirían .nuxt y el overlay,
# que es de una sola plataforma a la vez. Se detecta antes de tocar archivos.
otro_nuxt_dev() {
  local pid
  for pid in $(pgrep -f "@nuxt/cli/dist/dev" 2>/dev/null); do
    if [ "$(readlink -f "/proc/$pid/cwd" 2>/dev/null)" = "$FRONT" ]; then
      echo "$pid"
      return 0
    fi
  done
  return 1
}

if [ "$RESTORE_ONLY" = 0 ] && OTRO_PID=$(otro_nuxt_dev); then
  echo "❌ Ya hay un 'nuxt dev' corriendo sobre frontend/ (PID $OTRO_PID)."
  echo "   Nuxt no permite dos servidores dev en el mismo directorio, y el overlay"
  echo "   aplicado es de una sola plataforma a la vez."
  echo ""
  echo "   Opciones:"
  echo "     • detener el otro:  kill $OTRO_PID"
  echo "     • correr el segundo frontend desde otra copia del bundle:"
  echo "         git clone --recurse-submodules <url> sedema-bundle-app"
  exit 1
fi

PROJECT="${PLATFORM}-${ENVNAME}"
BUNDLE_ENV="$BUNDLE/.env.${PROJECT}"
FRONT_ENV_NAME=".env.${PLATFORM}-${TARGET}"

# Estado de la sesión de overlay: el manifiesto dice qué se copió y de qué tipo,
# y BACKUP guarda una copia intacta de cada archivo base sobreescrito. Restaurar
# desde esa copia (en vez de `git checkout`) funciona también con archivos base
# sin versionar, y permite distinguir "contenido base" de "edición de la persona
# usuaria" antes de escribir nada en platforms/.
STATE_DIR="${TMPDIR:-/tmp}/sigic-overlay-${PLATFORM}-${TARGET}"
STATE="$STATE_DIR/manifiesto"
BACKUP="$STATE_DIR/base"

# --------------------------------------------------------------- utilidades
overlay_files() {
  [ -d "$OVERLAY" ] || return 0
  (cd "$OVERLAY" && find . -type f ! -name '.gitkeep' -printf '%P\n' 2>/dev/null | sort)
}

json_get() { # json_get <archivo> <ruta.python>
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

env_get() { # env_get <VAR> — lee del .env del bundle
  [ -f "$BUNDLE_ENV" ] || return 0
  grep -m1 "^$1=" "$BUNDLE_ENV" | cut -d= -f2- || true
}

register() { # register NEW|BASE <ruta relativa>
  mkdir -p "$STATE_DIR"
  grep -qxF "$1 $2" "$STATE" 2>/dev/null || echo "$1 $2" >> "$STATE"
}

# ¿El archivo dentro de frontend/ es exactamente el base original? Pasa cuando
# alguien hace `git checkout` del archivo durante la sesión. En ese caso NO hay
# que empujarlo al overlay: sobrescribiría la personalización de la plataforma
# con el código del submodulo.
es_contenido_base() { # es_contenido_base <ruta relativa>
  [ -e "$BACKUP/$1" ] && cmp -s "$FRONT/$1" "$BACKUP/$1"
}

prune_dirs() { # borra directorios vacíos creados por el overlay, sin salir de frontend/
  local d="$1"
  while [ "$d" != "$FRONT" ] && [ -d "$d" ]; do
    rmdir "$d" 2>/dev/null || break
    d=$(dirname "$d")
  done
}

# ----------------------------------------------------------------- restaurar
restore_tree() {
  [ -f "$STATE" ] || return 0
  echo ""
  echo "🧹 Restaurando frontend/ ..."
  while read -r kind rel; do
    [ -n "${rel:-}" ] || continue
    src="$OVERLAY/$rel"
    dst="$FRONT/$rel"

    # Se guarda en el overlay solo lo que sea una edición real: distinto del
    # overlay y distinto del archivo base original (ver es_contenido_base).
    if [ -e "$dst" ] && [ -e "$src" ] && ! cmp -s "$dst" "$src" && ! es_contenido_base "$rel"; then
      cp -p "$dst" "$src"
      echo "   ← guardado en overlay: $rel"
    fi

    if [ "$kind" = "BASE" ] && [ -e "$BACKUP/$rel" ]; then
      cp -p "$BACKUP/$rel" "$dst"
    else
      rm -f "$dst"
      prune_dirs "$(dirname "$dst")"
    fi
  done < "$STATE"
  rm -rf "$STATE_DIR"
  echo "✅ frontend/ limpio (overlay vive solo en platforms/$PLATFORM/overrides/frontend/)"
}

if [ "$RESTORE_ONLY" = 1 ]; then
  restore_tree
  exit 0
fi

# ------------------------------------------------------------ aplicar overlay
apply_overlay() {
  local n=0
  while IFS= read -r rel; do
    [ -n "$rel" ] || continue
    src="$OVERLAY/$rel"; dst="$FRONT/$rel"
    if [ -e "$dst" ]; then
      # respaldar el archivo base antes de pisarlo (una sola vez por sesión)
      if [ ! -e "$BACKUP/$rel" ]; then
        mkdir -p "$BACKUP/$(dirname "$rel")"
        cp -p "$dst" "$BACKUP/$rel"
      fi
      register BASE "$rel"
    else
      register NEW "$rel"
    fi
    mkdir -p "$(dirname "$dst")"
    cp -p "$src" "$dst"
    n=$((n + 1))
  done < <(overlay_files)
  echo "🎨 Overlay aplicado: $n archivo(s) de platforms/$PLATFORM/overrides/frontend/ → frontend/"
}

# ----------------------------------------------- sincronización bidireccional
# Compara contenido; el lado con mtime más reciente gana. `cp -p` conserva la
# mtime, así que tras una copia ambos lados quedan iguales y el ciclo se corta.
watch_loop() {
  while true; do
    sleep 1
    while IFS= read -r rel; do
      [ -n "$rel" ] || continue
      src="$OVERLAY/$rel"; dst="$FRONT/$rel"
      if [ ! -e "$dst" ]; then
        mkdir -p "$(dirname "$dst")"
        cp -p "$src" "$dst"
        register NEW "$rel"
        echo "   → overlay: $rel"
        continue
      fi
      # mtime como disparador (barato); cmp solo como guarda antes de copiar
      if [ "$dst" -nt "$src" ]; then
        cmp -s "$dst" "$src" && continue
        if es_contenido_base "$rel"; then
          # alguien revirtió el archivo al código base (p. ej. `git checkout`):
          # se vuelve a aplicar el overlay en vez de pisarlo con el base
          cp -p "$src" "$dst"
          echo "   → overlay reaplicado: $rel"
        else
          cp -p "$dst" "$src"
          echo "   ← push-back: $rel"
        fi
      elif [ "$src" -nt "$dst" ]; then
        cmp -s "$src" "$dst" || { cp -p "$src" "$dst"; echo "   → overlay: $rel"; }
      fi
    done < <(overlay_files)
  done
}

WATCH_PID=""
LIMPIANDO=0
cleanup() {
  # Reentrancia: un Ctrl-C durante la restauración dispararía cleanup otra vez
  # en paralelo y el segundo pase vería archivos ya restaurados a su versión
  # base, empujándolos al overlay. Se bloquea el reingreso y se ignoran señales
  # mientras dura la limpieza.
  [ "$LIMPIANDO" = 1 ] && return 0
  LIMPIANDO=1
  trap '' INT TERM HUP

  [ -n "$WATCH_PID" ] && kill "$WATCH_PID" 2>/dev/null || true
  if [ "$KEEP" = 1 ]; then
    echo ""
    echo "⚠️  --keep: el overlay quedó aplicado dentro de frontend/."
    echo "    Limpiá con: scripts/dev-frontend.sh $PLATFORM $TARGET --restore"
    return 0
  fi
  restore_tree
}
trap cleanup EXIT INT TERM HUP

# --------------------------------------------------------------- puerto
if [ -z "$PORT" ] && [ -f "$PLATFORM_JSON" ]; then
  PORT=$(json_get "$PLATFORM_JSON" "ports.frontend_${TARGET}")
fi
if [ -z "$PORT" ]; then
  [ "$TARGET" = "admin" ] && PORT=3001 || PORT=3002
fi

# ------------------------------------------------- .env del frontend (dev)
# Valor de un feature flag: gana el del .env de la plataforma; si no está
# definido ahí, se usa el default de docker-compose.yml para este target.
flag() { # flag <VARIABLE> <default>
  local v
  v=$(env_get "$1")
  echo "${v:-$2}"
}

generate_front_env() {
  local base issuer cid csecret asecret
  base=$(env_get NGINX_BASE_URL)
  issuer=$(env_get SOCIALACCOUNT_OIDC_ID_TOKEN_ISSUER)
  [ -n "$issuer" ] || issuer="${base}/iam/realms/${PLATFORM}"

  local f_auth f_catalogo_vista f_catalogo_carga f_consulta f_iaa f_levantamiento

  if [ "$TARGET" = "admin" ]; then
    cid=$(env_get ADMIN_KEYCLOAK_CLIENT_ID)
    csecret=$(env_get ADMIN_KEYCLOAK_CLIENT_SECRET)
    asecret=$(env_get ADMIN_NUXT_AUTH_SECRET)
    # el contenedor frontend-admin fija estos cuatro en true
    f_auth=true
    f_catalogo_vista=true
    f_catalogo_carga=true
    f_consulta=true
  else
    cid=$(env_get APP_KEYCLOAK_CLIENT_ID)
    csecret=$(env_get APP_KEYCLOAK_CLIENT_SECRET)
    asecret=$(env_get APP_NUXT_AUTH_SECRET)
    f_auth=$(flag NUXT_PUBLIC_ENABLE_AUTH false)
    f_catalogo_vista=$(flag NUXT_PUBLIC_ENABLE_CATALOGO_VISTA true)
    f_catalogo_carga=$(flag NUXT_PUBLIC_ENABLE_CATALOGO_CARGA true)
    f_consulta=$(flag NUXT_PUBLIC_ENABLE_CONSULTA true)
  fi

  # IAA y Levantamiento siguen a sus proxies, igual que en docker-compose.yml
  f_iaa=$(flag ENABLE_IA_PROXY false)
  f_levantamiento=$(flag ENABLE_LEVANTAMIENTO_PROXY false)

  cat > "$FRONT/$FRONT_ENV_NAME" << EOF
# Generado por scripts/dev-frontend.sh desde $(basename "$BUNDLE_ENV")
# Plataforma: $PLATFORM | Target: $TARGET | Ambiente: $ENVNAME
NODE_ENV=development

# Auth (nuxt-auth + Keycloak)
NUXT_AUTH_SECRET=${asecret}
KEYCLOAK_CLIENT_ID=${cid}
KEYCLOAK_CLIENT_SECRET=${csecret}
KEYCLOAK_ISSUER=${issuer}
NUXT_PUBLIC_KEYCLOAK_CLIENT_ID=${cid}
NUXT_PUBLIC_KEYCLOAK_ISSUER=${issuer}
SOCIALACCOUNT_OIDC_ID_TOKEN_ISSUER=${issuer}

# Backend dockerizado de esta plataforma
NUXT_PUBLIC_GEONODE_URL=${base}
NUXT_PUBLIC_GEONODE_API=${base}/api/v2
NUXT_PUBLIC_GEOSERVER_URL=${base}/gs
NGINX_BASE_URL=${base}

# Este servidor dev
NUXT_PUBLIC_BASE_URL=http://localhost:${PORT}
NUXT_PUBLIC_AUTH_BASE_URL=http://localhost:${PORT}/api/auth
NUXT_APP_BASE_URL=/

# Features — se toman de $(basename "$BUNDLE_ENV"), que a su vez sale de
# platforms/$PLATFORM/env/$ENVNAME.env. Si un módulo no carga (404 del
# middleware habilitar_modulos.global.ts), su flag está en false acá.
NUXT_PUBLIC_ENABLE_AUTH=${f_auth}
NUXT_PUBLIC_ENABLE_CATALOGO_VISTA=${f_catalogo_vista}
NUXT_PUBLIC_ENABLE_CATALOGO_CARGA=${f_catalogo_carga}
NUXT_PUBLIC_ENABLE_CONSULTA=${f_consulta}
NUXT_PUBLIC_ENABLE_IAA=${f_iaa}
NUXT_PUBLIC_ENABLE_LEVANTAMIENTO=${f_levantamiento}
NUXT_PUBLIC_ENABLE_ACERCA_DE=$(flag NUXT_PUBLIC_ENABLE_ACERCA_DE false)
NUXT_PUBLIC_ENABLE_GEOCONTENIDOS=$(flag NUXT_PUBLIC_ENABLE_GEOCONTENIDOS false)
NUXT_PUBLIC_ENABLE_GEOHISTORIAS=$(flag NUXT_PUBLIC_ENABLE_GEOHISTORIAS false)
NUXT_PUBLIC_ENABLE_TABLEROS=$(flag NUXT_PUBLIC_ENABLE_TABLEROS false)
NUXT_PUBLIC_ENABLE_PANORAMAS=$(flag NUXT_PUBLIC_ENABLE_PANORAMAS false)
NUXT_PUBLIC_ENABLE_LANDING_BUILDER=$(flag NUXT_PUBLIC_ENABLE_LANDING_BUILDER false)
NUXT_PUBLIC_DEFAULT_PAGE=$(flag NUXT_PUBLIC_DEFAULT_PAGE /)
EOF
  echo "📝 Generado frontend/$FRONT_ENV_NAME"
}

if [ ! -f "$FRONT/$FRONT_ENV_NAME" ] || [ "$REGEN_ENV" = 1 ]; then
  if [ -f "$BUNDLE_ENV" ]; then
    generate_front_env
  else
    echo "❌ No existe $BUNDLE_ENV y falta frontend/$FRONT_ENV_NAME."
    echo "   Levantá el backend primero:  SIGIC_DEV=1 ./sigic_install.sh $PLATFORM $ENVNAME"
    exit 1
  fi
else
  echo "📝 Usando frontend/$FRONT_ENV_NAME (--regen-env para regenerarlo)"
fi

# ------------------------------------------------------------------ arrancar
[ -d "$FRONT/node_modules" ] || {
  echo "📦 Instalando dependencias del frontend (una sola vez)..."
  (cd "$FRONT" && npm install --legacy-peer-deps)
}

# Sesión anterior que murió sin restaurar: se recupera antes de aplicar de nuevo,
# para no perder el respaldo de los archivos base ni dejar restos en frontend/.
if [ -f "$STATE" ]; then
  echo "⚠️  Sesión anterior sin restaurar detectada — recuperando primero..."
  restore_tree
fi
rm -rf "$STATE_DIR"
apply_overlay

if [ "$WATCH" = 1 ]; then
  watch_loop &
  WATCH_PID=$!
  echo "👀 Sincronizando overlay en caliente (edítalo en cualquiera de los dos lados)"
fi

echo ""
echo "🚀 $PLATFORM / $TARGET  →  http://localhost:$PORT"
echo "   backend: $(env_get NGINX_BASE_URL)"
echo ""

cd "$FRONT"
npx nuxt dev --port "$PORT" --dotenv "$FRONT_ENV_NAME"
