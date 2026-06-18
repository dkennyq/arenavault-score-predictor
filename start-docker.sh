#!/bin/bash
set -e

# Script para iniciar ArenaVault con detección automática de puerto PostgreSQL disponible
# Si el puerto 5432 está ocupado, intentará automáticamente con 5433, 5434, etc.

START_PORT=5432
MAX_PORT=5442
SELECTED_PORT=""

echo "🔍 Buscando puerto disponible para PostgreSQL..."

for port in $(seq $START_PORT $MAX_PORT); do
    # Verificar si el puerto está en uso
    if ! command -v ss &> /dev/null; then
        # Fallback si no existe ss
        if ! netstat -tln 2>/dev/null | grep -q ":$port "; then
            if ! lsof -i :$port &>/dev/null; then
                SELECTED_PORT=$port
                echo "✅ Puerto disponible encontrado: $port"
                break
            fi
        else
            echo "⚠️ Puerto $port ocupado, probando siguiente..."
        fi
    else
        if ! ss -tln | grep -q ":$port "; then
            SELECTED_PORT=$port
            echo "✅ Puerto disponible encontrado: $port"
            break
        else
            echo "⚠️ Puerto $port ocupado, probando siguiente..."
        fi
    fi
done

if [ -z "$SELECTED_PORT" ]; then
    echo "❌ ERROR: No se encontró puerto disponible en el rango $START_PORT-$MAX_PORT"
    exit 1
fi

export POSTGRES_HOST_PORT=$SELECTED_PORT

echo "🚀 Iniciando Docker Compose con PostgreSQL en puerto $SELECTED_PORT..."
echo "   (La variable de entorno POSTGRES_HOST_PORT=$SELECTED_PORT se ha establecido)"

# Ejecutar docker-compose con los argumentos recibidos
if [ $# -eq 0 ]; then
    docker compose up --build
else
    docker compose "$@"
fi
