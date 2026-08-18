# 🏗️ Build stage
FROM node:22 AS builder

ARG PLATFORM_NAME
ARG NUXT_PUBLIC_APP_BASE_PATH

ENV NUXT_PUBLIC_APP_BASE_PATH=${NUXT_PUBLIC_APP_BASE_PATH:-/}

ENV NODE_ENV=production

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    make \
    g++ \
    libsqlite3-dev \
    && rm -rf /var/lib/apt/lists/*

COPY frontend/package*.json ./

# --ignore-scripts evita que npm ejecute el script prepare (nuxt prepare + patches)
# antes de que el código fuente esté disponible
RUN npm install --include=dev --legacy-peer-deps --ignore-scripts

COPY frontend/ .

# Overlays de plataforma — sobreescriben archivos del código base sin modificar el submodulo
COPY platforms/${PLATFORM_NAME}/overrides/frontend/ .

# El npm install de arriba usa --ignore-scripts porque el postinstall del proyecto
# necesita el código fuente, que en ese punto aún no estaba copiado. Ese flag es
# global: también saltó los postinstall de las dependencias. Ya con el código
# presente, se ejecutan aquí.
#
# npm rebuild: @vue-office/* declaran main=lib/index.js, y ese archivo NO viene en
# el tarball — lo genera su postinstall copiando lib/v3/index.js (elige v2 o v3
# según la versión de Vue instalada). Sin esto el build muere con
# "Failed to resolve entry for package @vue-office/docx".
#
# npm run postinstall: aplica nuxt prepare y los parches de focus-trap y nuxt-auth.
RUN npm rebuild @vue-office/docx @vue-office/excel @vue-office/pdf @vue-office/pptx \
    && npm run postinstall

RUN npm run build


# 🚀 Final stage
FROM node:22-slim

ENV NODE_ENV=production

WORKDIR /app

COPY --from=builder /app/.output/ .output/

# ipx es peer dependency de @nuxt/image y no queda bundleado por Nitro;
# se instala explícitamente para garantizar disponibilidad en runtime
RUN npm install ipx@2 --no-save --ignore-scripts

EXPOSE 3000

CMD ["node", ".output/server/index.mjs"]
