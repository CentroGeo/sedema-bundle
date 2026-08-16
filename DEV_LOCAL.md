# Guía de Desarrollo Local — SIGIC Multi-Plataforma

Cómo levantar este bundle en tu máquina (Linux con Docker) y desarrollar el frontend con
hot reload **tomando en cuenta los overlays de plataforma** (`platforms/<plataforma>/overrides/frontend/`).

Adaptada de la guía de SIGIC clásico. La diferencia central: este bundle no despliega *una*
plataforma, sino cualquiera de las que viven en `platforms/` (hoy `conafor`, `idegeo`, `sedema`),
y cada una puede tener archivos de frontend propios que se inyectan sobre el submódulo.

---

## Qué cambia respecto a la guía de SIGIC clásico

| Tema | SIGIC clásico | Este bundle |
|------|---------------|-------------|
| Instalación | `python3 create-envfile.py` a mano | `./sigic_install.sh <plataforma> <ambiente>` |
| Config por entorno | flags en la línea de comandos | `platforms/<plataforma>/platform.json` + `env/<ambiente>.env` |
| Clientes de Keycloak | se crean a mano en la consola | los importa el instalador (`scripts/import-keycloak-clients.sh`) |
| Fixture `socialaccount` | se carga a mano desde el admin de Django | la carga el instalador |
| Puerto 80 / 5432 | los publica el stack | los publica solo `nginx-proxy`; el resto usa puertos aleatorios |
| Hostname local | `localhost` | `<plataforma>.localhost` (permite varias plataformas a la vez) |
| Personalización | editar el submódulo | overlays en `platforms/<plataforma>/overrides/frontend/` |
| Proxies de nginx en dev | comentar líneas del `docker-compose.yml` | `docker-compose.dev.yml` (no se toca ningún archivo versionado) |

---

## Arquitectura del entorno local

```
                     Host (tu máquina)
┌──────────────────────────────────────────────────────────────────┐
│  nginx-proxy :80        ← único puerto publicado                  │
│    └── server_name sedema.localhost → nginx4sedema-local          │
│                                                                    │
│  Docker: stack sedema-local             Local: nuxt dev            │
│  ┌──────────────────────────────┐       ┌───────────────────────┐ │
│  │ nginx4sedema-local           │       │ frontend admin :3021  │ │
│  │ django4sedema-local          │       │ frontend app   :3022  │ │
│  │ geoserver / db / keycloak    │       │                       │ │
│  │ celery / rabbitmq / memcached│       │ overlay sincronizado  │ │
│  └──────────────────────────────┘       │ desde platforms/...   │ │
│                                          └───────────────────────┘ │
└──────────────────────────────────────────────────────────────────┘
```

- **Docker** levanta el backend completo de *una* plataforma, aislado por `COMPOSE_PROJECT_NAME=<plataforma>-<ambiente>`.
- **`nuxt dev`** corre en el host con hot reload, apuntando al backend dockerizado.
- El **overlay de la plataforma** se aplica sobre `frontend/` y se sincroniza en caliente, replicando lo que el `Dockerfile` hace con `COPY platforms/${PLATFORM_NAME}/overrides/frontend/ .`

---

## Paso 0 — Prerrequisitos

```bash
sudo apt install -y jq rsync            # jq lo usa sigic_install.sh
node --version                          # 22.x recomendado (el Dockerfile usa node:22)
docker compose version                  # >= 2.24 (docker-compose.dev.yml usa !override)
```

Repo clonado con submódulos:

```bash
git clone --recurse-submodules <url> sedema-bundle
cd sedema-bundle
git submodule update --init --recursive
```

Resolución del hostname local (una vez):

```bash
echo "127.0.0.1 sedema.localhost conafor.localhost idegeo.localhost" | sudo tee -a /etc/hosts
```

Libera el puerto 80 si tienes Apache/nginx del sistema corriendo:

```bash
sudo lsof -i :80          # debe estar vacío
sudo systemctl stop apache2   # si aplica
```

> No necesitas liberar el 5432: en modo plataforma Postgres no publica puerto fijo.

> **Aviso:** el instalador **sobrescribe el `.env` de la raíz**. Si tienes uno con
> configuración que te importa, respáldalo (`cp .env .env.backup`). El `.env` de cada
> plataforma queda guardado aparte en `.env.<plataforma>-<ambiente>`.

---

## Paso 1 — El ambiente `local` de la plataforma

Cada plataforma tiene sus ambientes en `platforms/<plataforma>/env/`. Este flujo agrega `local.env`:

```ini
# platforms/sedema/env/local.env
hostname=sedema.localhost
env_type=dev
oidc_provider_url=http://sedema.localhost/iam/realms/sedema
https_mode=http
```

Ya existen para `sedema`, `conafor` e `idegeo`. Para una plataforma nueva, copia ese archivo
y cambia el nombre en las tres líneas.

Los puertos de desarrollo salen de `platform.json`:

| Plataforma | hostname local | frontend admin | frontend app |
|------------|----------------|----------------|--------------|
| idegeo | `idegeo.localhost` | 3001 | 3002 |
| conafor | `conafor.localhost` | 3011 | 3012 |
| sedema | `sedema.localhost` | 3021 | 3022 |

---

## Paso 2 — Levantar el backend

```bash
SIGIC_DEV=1 ./sigic_install.sh sedema local
```

`SIGIC_DEV=1` es el modo de desarrollo local:

1. Quita los profiles de `frontend` → no construye ni levanta los contenedores Nuxt (ahorra ~15 min de build).
2. Agrega `docker-compose.dev.yml`, que quita de nginx los montajes `z-frontend-admin.conf` / `z-frontend-app.conf` / `z-ia-proxy.conf`. Sin esto nginx entra en crash-loop con `host not found in upstream "frontend-admin"`.

Sin `SIGIC_DEV=1` el comando funciona igual que siempre (todo dockerizado), útil para validar el build real.

El instalador hace, en orden:

| Paso | Resultado |
|------|-----------|
| Lee `platform.json` + `env/local.env` | flavor base, flags y hostname |
| `create-envfile.py` | genera `.env` y lo copia a `.env.sedema-local` |
| `create-keycloak-jsons.py` | genera los JSON de clientes en `overrides/keycloak/sedema-local/` |
| Levanta `nginx-proxy` y genera `proxy/conf.d/sedema-local.conf` | enruta `sedema.localhost` al stack |
| `docker compose up -d` (profiles `geonode,oidc`) | backend completo |
| `import-keycloak-clients.sh` | crea el realm `sedema` y los 3 clientes |
| `create-socialaccount-fixture.py` + `loaddata` | conecta GeoNode con Keycloak |

La primera vez tarda: las migraciones de Django pueden llevar 10-30 min. El script espera y
reintenta `init-keycloak-db` solo si falla. Al final imprime `ADMIN_PASSWORD` y `GEOSERVER_ADMIN_PASSWORD`.

Verificación:

```bash
docker ps --filter name=sedema-local
curl -sI http://sedema.localhost/catalogue/ | head -1     # 200 / 302
curl -s http://sedema.localhost/iam/realms/sedema | head -c 80
```

---

## Paso 3 — Habilitar los puertos dev en Keycloak

Los clientes importados apuntan a `http://sedema.localhost/admin/` y `/app/` (frontends
dockerizados). En dev local Nuxt corre en `localhost:3021`, así que hay que agregar esas URIs:

```bash
scripts/dev-keycloak-uris.sh sedema local
```

Agrega `http://localhost:3021/*` y `http://localhost:3022/*` a los clientes `sigic-admin` y
`sigic-app` **conservando** las URIs de producción. Es idempotente: puedes repetirlo cuando
quieras y hay que volver a correrlo si reinstalas la plataforma (el import vuelve a poner las
URIs originales).

---

## Paso 4 — Frontend con overlays y hot reload

```bash
scripts/dev-frontend.sh sedema admin     # o: sedema app
```

> **Uno a la vez por copia del bundle.** Nuxt toma un lock por directorio de
> proyecto: un segundo `nuxt dev` sobre el mismo `frontend/` muere con
> *"Another Nuxt dev is already running"* y deja el puerto muerto (además
> compartirían `.nuxt` y el overlay, que es de una sola plataforma). Para tener
> admin y app arriba al mismo tiempo, clona el bundle en otra carpeta y corre
> ahí el segundo. El script detecta el conflicto y aborta antes de tocar archivos.

Cada comando:

1. Genera `frontend/.env.sedema-admin` (o `-app`) leyendo secretos, issuer y URLs de `.env.sedema-local` — no hay que copiar y pegar client secrets.
2. Instala dependencias si falta `node_modules`.
3. **Aplica el overlay**: copia `platforms/sedema/overrides/frontend/**` dentro de `frontend/`, igual que el `Dockerfile`.
4. **Sincroniza en caliente** overlay ⇄ `frontend/` mientras el servidor corre.
5. Arranca `nuxt dev --port 3021 --dotenv .env.sedema-admin`.
6. Al salir (Ctrl-C) **restaura `frontend/`**: borra los archivos nuevos y repone los archivos base desde una copia de respaldo que hizo antes de pisarlos (no usa `git`, así que también funciona con archivos base sin versionar).

### Por qué copiar y no enlazar

Nuxt/Vite sirven y vigilan archivos **dentro** del proyecto. Un symlink a `../platforms/...`
cae fuera de la raíz servida por Vite y rompe el HMR. Copiando, los archivos del overlay son
archivos normales del proyecto: HMR de `.vue`, recarga de `.scss`, auto-import de componentes
nuevos y `public/` estático funcionan idéntico al código base.

### La sincronización es en los dos sentidos

| Editas en… | Qué pasa |
|------------|----------|
| `platforms/sedema/overrides/frontend/pages/index.vue` | se copia a `frontend/pages/index.vue` → HMR |
| `frontend/pages/index.vue` (archivo que *está* en el overlay) | se copia de vuelta al overlay (`← push-back`) |
| `frontend/components/...` (archivo que **no** está en el overlay) | no se toca: es código base del submódulo |
| `git checkout` de un archivo del overlay dentro de `frontend/` | se detecta que volvió al contenido base y se reaplica el overlay (nunca se empuja el código base a `platforms/`) |

Es decir: puedes trabajar en `frontend/` como siempre, sin pensar en rutas raras. Lo que sea
override de la plataforma queda guardado en `platforms/` automáticamente, incluido al salir.

### Agregar un archivo nuevo al overlay

```bash
# nuevo componente exclusivo de sedema
mkdir -p platforms/sedema/overrides/frontend/components/base
$EDITOR platforms/sedema/overrides/frontend/components/base/MiBanner.vue
```

Con el script corriendo, aparece en `frontend/` en ~1 s y Nuxt lo auto-importa. Para
sobrescribir un archivo base, replica su ruta relativa dentro de `overrides/frontend/`.

### Módulos y feature flags

Cada módulo del frontend está detrás de un flag. El middleware global
`habilitar_modulos.global.ts` devuelve **404** para cualquier ruta cuyo flag esté en `false`,
y `MainNavegacion.vue` esconde su enlace.

| Ruta | Flag | Requiere sesión |
|------|------|-----------------|
| `/catalogo/explorar` | `NUXT_PUBLIC_ENABLE_CATALOGO_VISTA` | no |
| `/catalogo/cargar-archivos`, `/catalogo/mis-archivos` | `+ ENABLE_CATALOGO_CARGA` + `ENABLE_AUTH` | sí |
| `/consulta` | `NUXT_PUBLIC_ENABLE_CONSULTA` | no |
| `/ia` | `NUXT_PUBLIC_ENABLE_IAA` + `ENABLE_AUTH` | sí |
| `/levantamiento` | `NUXT_PUBLIC_ENABLE_LEVANTAMIENTO` + `ENABLE_AUTH` | sí |
| `/geocontenidos/**` | `NUXT_PUBLIC_ENABLE_GEOCONTENIDOS` | sí (`pages/geocontenidos.vue` usa middleware `auth`) |
| `/geocontenidos/panoramas` | `+ NUXT_PUBLIC_ENABLE_PANORAMAS` | sí |
| `/geohistorias` (visor público) | `NUXT_PUBLIC_ENABLE_GEOHISTORIAS` | no |
| `/tableros` (visor público) | `NUXT_PUBLIC_ENABLE_TABLEROS` | no |
| `/acerca-de` | `NUXT_PUBLIC_ENABLE_ACERCA_DE` | no |
| `/landing-builder` | `NUXT_PUBLIC_ENABLE_LANDING_BUILDER` + `ENABLE_AUTH` | sí (admin) |

**Dónde se activan:** en `platforms/<plataforma>/env/<ambiente>.env`. `sigic_install.sh` copia
esas claves al `.env` del bundle, de donde las leen tanto el contenedor Nuxt como
`scripts/dev-frontend.sh` al generar el `.env` del frontend.

```ini
# platforms/sedema/env/local.env
NUXT_PUBLIC_ENABLE_GEOCONTENIDOS=true
NUXT_PUBLIC_ENABLE_PANORAMAS=true
```

Para aplicarlo sin reinstalar el backend: edita el mismo par de claves en
`.env.<plataforma>-<ambiente>` y regenera el `.env` del frontend:

```bash
scripts/dev-frontend.sh sedema admin --regen-env
```

> Los valores se comparan como cadena `'true'` en minúsculas. `True` o `1` no activan nada.

### Opciones útiles

```bash
scripts/dev-frontend.sh sedema admin --port 3031     # otro puerto
scripts/dev-frontend.sh sedema admin --regen-env     # regenerar el .env del frontend
scripts/dev-frontend.sh sedema admin --no-watch      # aplicar overlay una vez, sin sync
scripts/dev-frontend.sh sedema admin --keep          # no restaurar al salir
scripts/dev-frontend.sh sedema admin --restore       # limpiar frontend/ tras un crash
```

> Si el script muere sin restaurar (kill -9, corte de luz), `git -C frontend status` mostrará
> los archivos del overlay. `--restore` lo limpia guardando antes tus ediciones; la siguiente
> corrida del script también lo detecta y recupera sola antes de aplicar el overlay de nuevo.

---

## Paso 5 — Verificación final

| Servicio | URL | Qué debe verse |
|----------|-----|----------------|
| GeoNode catálogo | http://sedema.localhost/catalogue/ | interfaz de GeoNode |
| Admin de Django | http://sedema.localhost/geonode-admin/ | login `admin` / `ADMIN_PASSWORD` del `.env.sedema-local` |
| Keycloak | http://sedema.localhost/iam/ | consola, `kadmin` / `kadmin` |
| GeoServer | http://sedema.localhost/gs/ | interfaz de GeoServer |
| Frontend admin | http://localhost:3021/ | Nuxt con el overlay de sedema |
| Frontend app | http://localhost:3022/ | app pública con el overlay de sedema |

Prueba de que el overlay está activo: la portada debe ser la de `platforms/sedema/overrides/frontend/pages/index.vue`
(logos CDMX/SEDEMA, video de fondo), no la genérica del submódulo.

---

## Operación diaria

Un helper para no repetir flags:

```bash
dc() {
  COMPOSE_PROFILES=geonode,oidc COMPOSE_PROJECT_NAME=sedema-local \
  docker compose --env-file .env.sedema-local \
    -f docker-compose.yml -f docker-compose.platform.yml -f docker-compose.dev.yml "$@"
}

dc ps
dc logs -f django
dc restart nginx
dc down            # apagar (conserva volúmenes)
dc down -v         # borrar TODO: base de datos, Keycloak, GeoServer
```

Reinstalar sin perder datos: `SIGIC_DEV=1 ./sigic_install.sh sedema local` detecta
`.env.sedema-local` y preserva las contraseñas de base de datos.

---

## Varias plataformas a la vez

Cada plataforma tiene su propio `COMPOSE_PROJECT_NAME`, su hostname y sus puertos de frontend,
así que conviven:

```bash
SIGIC_DEV=1 ./sigic_install.sh sedema local
SIGIC_DEV=1 ./sigic_install.sh conafor local
scripts/dev-frontend.sh sedema admin     # :3021
scripts/dev-frontend.sh conafor admin    # :3011
```

Lo único que **no** se puede paralelizar es `nuxt dev` sobre el mismo `frontend/`: el overlay se
aplica sobre ese árbol (una plataforma a la vez) y Nuxt además toma un lock por directorio. Eso
vale también para admin + app de la *misma* plataforma. Si necesitas dos servidores dev al mismo
tiempo, clona el bundle en otra carpeta y corre el segundo ahí.

---

## Validar el overlay como en producción

Antes de mergear, verifica que el overlay también funciona en el build real:

```bash
./sigic_install.sh sedema local          # sin SIGIC_DEV → construye las imágenes Nuxt
```

Construye con `overrides/frontend/Dockerfile` (`COPY platforms/sedema/overrides/frontend/ .`),
levanta `frontendadmin4sedema-local` y `frontendapp4sedema-local`, y los sirve a través de nginx en
http://sedema.localhost/admin/ y http://sedema.localhost/app/.

> Corre esto con `frontend/` limpio (sin overlay aplicado): el Dockerfile lo aplica solo.

---

## Troubleshooting

### `jq: command not found`
`sudo apt install jq`. `sigic_install.sh` lo necesita para leer `platform.json`.

### `invalid empty volume spec` al hacer `docker compose ...`
Alguna variable `ENABLE_*_PROXY` quedó vacía en el `.env` que estás usando. Las genera
`create-envfile.py` como `True`/`False`; si editaste el `.env` a mano y las dejaste vacías,
regenera con `SIGIC_DEV=1 ./sigic_install.sh <plataforma> local` o pon `False`.

### nginx en `Restarting` → `host not found in upstream "frontend-admin"`
Levantaste sin `SIGIC_DEV=1` pero sin los contenedores de frontend. Reinstala con
`SIGIC_DEV=1` o levanta también el profile `frontend`.

### `Invalid parameter: redirect_uri` al hacer login desde Nuxt
Falta el paso 3, o reinstalaste la plataforma (el import de Keycloak repone las URIs originales):
`scripts/dev-keycloak-uris.sh sedema local`.

### `sedema.localhost` no resuelve
Falta la línea en `/etc/hosts` (Paso 0). Verifica con `getent hosts sedema.localhost`.

### El navegador no llega al stack pero los contenedores están arriba
`docker ps --filter name=nginx-proxy` y `cat proxy/conf.d/sedema-local.conf`. Si editaste algo:
`docker exec nginx-proxy nginx -s reload`.

### `init-keycloak-db` falla con `password authentication failed`
El volumen de Postgres se creó con otra contraseña. Empieza limpio:
`dc down -v` y reinstala. **Borra todos los datos de esa plataforma.**

### Un módulo devuelve 404 (`/geocontenidos`, `/ia`, `/acerca-de`, …)

Su feature flag está en `false`. Lo hace el middleware global
`habilitar_modulos.global.ts` con `abortNavigation()`. Revisa el flag en el `.env` que está
usando el servidor dev:

```bash
grep ENABLE frontend/.env.<plataforma>-<target>
```

Actívalo en `platforms/<plataforma>/env/<ambiente>.env` (ver "Módulos y feature flags") y
regenera con `--regen-env`. **Los cambios de `.env` no se recargan en caliente: hay que
reiniciar el servidor dev.**

Si el flag ya está en `true` y la ruta redirige a `/`, entonces falta iniciar sesión:
`pages/geocontenidos.vue` (como otras) usa el middleware `auth`.

### El servidor dev arranca pero el puerto no responde

Hay otro `nuxt dev` sobre el mismo `frontend/`. Nuxt toma un lock por directorio y el segundo
muere con `Another Nuxt dev is already running`. Uno a la vez por copia del bundle.

```bash
pgrep -af "@nuxt/cli/dist/dev"
```

### El frontend no muestra los cambios del overlay
1. ¿El script sigue corriendo? La sincronización solo ocurre mientras vive.
2. ¿El archivo está bajo `platforms/<plataforma>/overrides/frontend/` con la misma ruta relativa que en `frontend/`?
3. Archivos de `public/` no tienen HMR: recarga la página (Ctrl-Shift-R).

### `frontend/` quedó sucio en git
`scripts/dev-frontend.sh <plataforma> <target> --restore`.

### Django tarda muchísimo la primera vez
Normal: migraciones + `collectstatic`. `dc logs -f django` para seguirlo.

---

## Diferencias con producción

| Aspecto | Producción (`prd`) | Dev local (`local`) |
|---------|--------------------|---------------------|
| Hostname | `sedema-dev.geosuitemp.centrogeo.org.mx` | `sedema.localhost` |
| HTTPS | `externalhttps` (Apache externo termina TLS) | `http` |
| Frontends | contenedores Nuxt detrás de nginx (`/admin/`, `/app/`) | `nuxt dev` en el host (`:3021`, `:3022`) |
| Overlay de plataforma | `COPY` en el build de la imagen | copiado y sincronizado por `dev-frontend.sh` |
| Profiles | `geonode,oidc,frontend` | `geonode,oidc` |
| Puertos publicados | solo `nginx-proxy` :80 | igual |

---

## Archivos que agrega este flujo

| Archivo | Para qué |
|---------|----------|
| `platforms/<plataforma>/env/local.env` | ambiente `local` de cada plataforma |
| `docker-compose.dev.yml` | quita de nginx los proxies a los frontends dockerizados |
| `scripts/dev-frontend.sh` | overlay + hot reload + `.env` del frontend |
| `scripts/dev-keycloak-uris.sh` | agrega los puertos dev a los clientes de Keycloak |
| `SIGIC_DEV=1` en `sigic_install.sh` | instala sin construir ni levantar los frontends |

`platform.json` de cada plataforma ganó un bloque `ports` con los puertos de frontend (lo lee
`dev-frontend.sh`; el resto del flujo lo ignora).
