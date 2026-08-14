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

RUN npm run build


# 🚀 Final stage
FROM node:22-slim

ENV NODE_ENV=production

WORKDIR /app

COPY --from=builder /app/.output/ .output/

# ipx es peer dependency de @nuxt/image; @vue-office/* son externos al bundle del servidor
RUN npm install ipx@2 \
    @vue-office/docx@1.6.3 \
    @vue-office/excel@1.7.14 \
    @vue-office/pptx@1.0.1 \
    @vue-office/pdf@2.0.10 \
    --no-save --ignore-scripts --legacy-peer-deps

EXPOSE 3000

CMD ["node", ".output/server/index.mjs"]
