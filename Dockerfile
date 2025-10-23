# ---- Build stage ----
FROM node:20-alpine AS build
WORKDIR /app

# Copiar manifest y lock si existe (sin fallar si no está)
COPY package.json ./
COPY package-lock.json* . 2>/dev/null || true

# Si hay lock -> npm ci; si no -> npm install
RUN if [ -f package-lock.json ] || [ -f npm-shrinkwrap.json ]; then \
      npm ci; \
    else \
      npm install; \
    fi

# Copiar el resto del código y construir
COPY . .
RUN npm run build

# ---- Runtime stage ----
FROM nginx:1.27-alpine
COPY --from=build /app/dist /usr/share/nginx/html
EXPOSE 80
HEALTHCHECK --interval=30s --timeout=3s CMD wget -qO- http://localhost:80/ || exit 1
