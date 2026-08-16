# Local dev login & API troubleshooting

How to fix the two bugs that block `/mapas` (and most authenticated pages) on a fresh `COMPOSE_PROFILES=geonode,oidc docker compose up -d` install when running the frontend locally on `:3001` / `:3002`.

Symptoms reported in the browser:

- `XHR GET http://localhost/api/v2/sigic-maps/?page_size=12&page=1 → 404 Not Found`
- `XHR GET http://localhost:3001/api/gnoxy/api/v2/account/me/profile/ → 401 Unauthorized`
- Browser banner: *"Este sitio te pide que inicies sesión."* even though Keycloak login succeeded.

There are two **independent** root causes. You must fix both — fixing only one keeps the other failing.

---

## Bug 1 — `404 /api/v2/sigic-maps/`

### Cause

The `sigic_mapas` Django app is in the local `geonode/` submodule source but **not in the running container**. The default image `ghcr.io/centrogeo/sigic-geonode-wrapper/sigic_geonode:latest` published on GHCR was built before the `feat(idegeo-mapas)` commit (`6afb399`). So `INSTALLED_APPS` inside the container does not include `sigic_geonode.sigic_mapas`, and `/api/v2/sigic-maps/` is unrouted.

You can confirm with:

```bash
docker exec django4sigic python -c \
  "from django.conf import settings; print('sigic_mapas' in str(settings.INSTALLED_APPS))"
```

If this prints `False`, the image is stale.

### Fix

Rebuild the django image from local source, recreate both services that share the image, run migrations.

```bash
cd /home/norman/Documentos/GeoNode/SIGIC/idegeo-bundle

# Rebuild from local ./geonode submodule (no cache, ~2 min)
COMPOSE_PROFILES=geonode,oidc docker compose build --no-cache django

# Recreate django + celery (both share the image via the x-common-django anchor)
COMPOSE_PROFILES=geonode,oidc docker compose up -d --force-recreate django celery

# Apply sigic_mapas migrations (and any other pending ones)
docker exec django4sigic python manage.py migrate
```

### Verify

```bash
curl -s -o /dev/null -w "%{http_code}\n" http://localhost/api/v2/sigic-maps/ \
  -H "Accept: application/json"
# expected: 200

docker exec django4sigic python manage.py showmigrations sigic_mapas
# expected: [X] 0001_initial, [X] 0002_..., [X] 0003_...
```

---

## Bug 2 — `401` on authenticated endpoints + login loop

### Cause

The `.env` (and `frontend/.env`, `frontend/.env.app`) all configure the OIDC issuer as:

```
SOCIALACCOUNT_OIDC_ID_TOKEN_ISSUER=http://localhost/iam/realms/idegeo
KEYCLOAK_ISSUER=http://localhost/iam/realms/idegeo
NUXT_PUBLIC_KEYCLOAK_ISSUER=http://localhost/iam/realms/idegeo
```

This URL is correct from the **browser's** point of view (`localhost` = your machine, hits nginx on port 80 → keycloak). But inside the `django` and `celery` containers, `localhost` resolves to the container itself — there is no Keycloak listening there.

When Django tries to validate a JWT it received via `Authorization: Bearer ...`, it must fetch the JWKS (signing keys) from the OIDC issuer URL. The fetch silently fails with `Connection refused`, the JWT cannot be validated, the request is rejected with `401`. Django's allauth then redirects to the login page, producing the *"Este sitio te pide iniciar sesión"* loop even though the user already has a valid Keycloak session.

You can confirm with:

```bash
docker exec django4sigic python -c \
  "import requests; r = requests.get('http://localhost/iam/realms/idegeo/.well-known/openid-configuration', timeout=5); print(r.status_code)"
```

If this raises `ConnectionError` (or returns `000`), Django cannot reach Keycloak.

### Fix — add `extra_hosts` to django/celery

Map `localhost` inside the django+celery containers to the Docker host gateway (the IP of the Docker bridge, where nginx port 80 is published). This way, Python's `requests` library transparently falls back from `127.0.0.1` (the container itself, refused) to the gateway IP (the host, where nginx is listening).

Edit `docker-compose.yml`. In the shared `x-common-django` anchor (top of file, ~line 7), add `extra_hosts`:

```yaml
x-common-django: &default-common-django
  image: ghcr.io/centrogeo/sigic-geonode-wrapper/sigic_geonode:latest
  build:
    context: ./geonode
    dockerfile: Dockerfile
  restart: unless-stopped
  env_file:
    - .env
  extra_hosts:                     # ← add these two lines
    - "localhost:host-gateway"
  volumes:
    ...
```

Both `django` and `celery` inherit from this anchor — single edit covers both.

Recreate the containers:

```bash
COMPOSE_PROFILES=geonode,oidc docker compose up -d --force-recreate django celery
```

### Why `localhost` and not a different name?

The issuer URL is hard-coded into the JWT's `iss` claim by Keycloak. Django strict-compares it against `SOCIALACCOUNT_OIDC_ID_TOKEN_ISSUER`. So we cannot just change the URL inside the container — both browser and Django must agree on the same issuer string. The cleanest local fix is: keep `localhost` everywhere, but make `localhost` resolvable from inside the container via the host gateway.

### Why does Python work but `curl` from the same container doesn't?

`curl localhost` connects to the first IP returned (`127.0.0.1`), gets `Connection refused`, **gives up** with exit 7. Python's `urllib3`/`requests` (used by Django) iterates through every address that `getaddrinfo` returns — so it tries `127.0.0.1`, fails, then tries the gateway IP (added by `extra_hosts`), and succeeds.

If you want to verify the routing manually, force curl to use the gateway:

```bash
docker exec django4sigic curl -s -o /dev/null -w "%{http_code}\n" \
  --resolve localhost:80:172.17.0.1 \
  http://localhost/iam/realms/idegeo/.well-known/openid-configuration
# expected: 200
```

### Verify

After recreating, hard-refresh the browser, **clear cookies** for `localhost:3001` and `localhost:3002` (a stale next-auth session may hold an `accessToken` that Django previously rejected), then log in again.

```bash
# From inside django container, OIDC discovery should reach Keycloak:
docker exec django4sigic python -c \
  "import requests; print(requests.get('http://localhost/iam/realms/idegeo/.well-known/openid-configuration', timeout=5).status_code)"
# expected: 200

# After login, with a fresh JWT in your browser, /account/me/profile/ should return 200.
# If you have a token at hand:
TOKEN=...   # access_token from /api/auth/session in the browser dev tools
curl -s -o /dev/null -w "%{http_code}\n" \
  -H "Authorization: Bearer $TOKEN" \
  http://localhost/api/v2/account/me/profile/
# expected: 200
```

---

## Order of operations

1. Apply Bug 2 patch to `docker-compose.yml` (the `extra_hosts` line).
2. Rebuild django: `docker compose build --no-cache django`.
3. Recreate: `docker compose up -d --force-recreate django celery`.
4. Migrate: `docker exec django4sigic python manage.py migrate`.
5. In the browser: clear cookies for `localhost:3001` / `localhost:3002`, hard-refresh, log in via Keycloak, navigate to `/mapas`.

---

## Common follow-up issues

| Symptom | Likely cause | Action |
|---|---|---|
| Still `401` after fresh login | Token issuer mismatch, audience mismatch, or clock skew | `docker logs django4sigic --tail 200 \| grep -iE "oidc\|jwt\|401\|profile"` |
| `/api/v2/sigic-maps/` returns `200` but with `{"results": []}` | Empty DB, expected on a fresh install | Create a map via the "Crear mapa" button or `POST /api/v2/sigic-maps/` |
| Login redirects but never lands back on the app | Keycloak client redirect URIs not set | In Keycloak admin, on `idegeo-admin` / `idegeo-app` clients, add `http://localhost:3001/api/auth/callback/keycloak` and `http://localhost:3002/api/auth/callback/keycloak` to **Valid redirect URIs**, plus `http://localhost:3001` / `http://localhost:3002` (or `+`) to **Web origins** |
| `KEYCLOAK_CLIENT_SECRET` errors during token exchange | `.env` placeholder still present | Copy the real client secret from the Keycloak admin → `Clients → idegeo-admin → Credentials` and update both `frontend/.env` and `frontend/.env.app` |

---

## Production note

In a real deployment, the public hostname (e.g. `idegeo.centrogeo.org.mx`) is reachable from both the browser and the Docker containers via normal DNS, and TLS is terminated at nginx. The `extra_hosts` workaround is **only needed for local development with `localhost`**. Do not ship it to prod.
