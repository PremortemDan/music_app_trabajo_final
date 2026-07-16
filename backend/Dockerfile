# ---- Etapa de build ----
FROM node:20-alpine AS builder

WORKDIR /app

# Instalar dependencias necesarias para compilar módulos nativos (bcrypt)
RUN apk add --no-cache python3 make g++

# Copiar archivos de dependencias primero para cachear capa
COPY package.json package-lock.json ./
RUN npm ci

# Copiar código fuente y prisma schema
COPY tsconfig.json ./
COPY src/ ./src/
COPY prisma/ ./prisma/

# Generar cliente de Prisma
RUN npx prisma generate

# Compilar TypeScript
RUN npm run build

# ---- Etapa de producción ----
FROM node:20-slim

WORKDIR /app

# Solo lo necesario para runtime (bcrypt requiere python3 make g++)
RUN apt-get update && apt-get install -y --no-install-recommends python3 make g++ openssl libssl-dev && rm -rf /var/lib/apt/lists/*

COPY --from=builder /app/package.json /app/package-lock.json ./
RUN npm ci --omit=dev

# Copiar el cliente de prisma generado y el código compilado
COPY --from=builder /app/node_modules/.prisma ./node_modules/.prisma
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/prisma ./prisma

# Crear directorio de uploads
RUN mkdir -p /app/uploads

# Copiar entrypoint
COPY entrypoint.sh ./entrypoint.sh
RUN chmod +x entrypoint.sh

EXPOSE 3000

ENTRYPOINT ["./entrypoint.sh"]