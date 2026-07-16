#!/bin/sh
set -e

echo "🔄 Ejecutando migraciones de Prisma..."
npx prisma migrate deploy

echo "🚀 Iniciando servidor..."
exec node dist/index.js