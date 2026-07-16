# ---- Etapa de build ----
FROM node:20 AS builder

WORKDIR /app

# Instalar dependencias necesarias para compilar módulos nativos (bcrypt)
RUN apt-get update && apt-get install -y --no-install-recommends python3 make g++ && rm -rf /var/lib/apt/lists/*

# Copiar archivos de dependencias primero para cachear capa
COPY package.json package-lock.json ./
RUN npm ci

# Copiar código fuente y prisma schema
COPY tsconfig.json ./
COPY src/ ./src/
COPY prisma/ ./prisma/

# Generar cliente de Prisma (solo para tener el cliente TS, los binarios se regeneran en prod)
RUN npx prisma generate

# Compilar TypeScript
RUN npm run build

# ---- Etapa de producción ----
FROM node:20-slim

WORKDIR /app

# Solo lo necesario para runtime (bcrypt requiere python3 make g++, openssl para prisma)
RUN apt-get update && apt-get install -y --no-install-recommends python3 make g++ openssl libssl-dev && rm -rf /var/lib/apt/lists/*

COPY --from=builder /app/package.json /app/package-lock.json ./
RUN npm ci --omit=dev

# Copiar el código compilado y prisma schema
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/prisma ./prisma

# Regenerar el cliente de Prisma para el target debian-openssl-3.0.x
RUN npx prisma generate

# Crear directorio de uploads
RUN mkdir -p /app/uploads

# Copiar entrypoint
COPY entrypoint.sh ./entrypoint.sh
RUN chmod +x entrypoint.sh

EXPOSE 3000

ENTRYPOINT ["./entrypoint.sh"]