# ArenaVault Score Predictor

Sistema de predicción de puntajes para Arena of Valor.

## Stack Tecnológico

- **Frontend**: HTML/JavaScript/CSS (interfaz simple y rápida)
- **Backend**: .NET 10 Web API con Entity Framework Core
- **Base de Datos**: PostgreSQL 16
- **Containerización**: Docker & Docker Compose
- **CI/CD**: GitHub Actions con deployment automático
- **Deployment**: Soporta Railway y Azure

## Requisitos Previos

- Docker Desktop instalado
- Docker Compose instalado

## Inicio Rápido

### Paso 1: Generar el archivo .env (IMPORTANTE)

El archivo `.env` contiene las URLs de la API y el puerto de PostgreSQL. **Debes generarlo antes de iniciar Docker.**

**Para servidor de pruebas / remoto:**
```bash
# Windows (PowerShell)
.\generate-env.ps1

# Linux/Mac
chmod +x generate-env.sh
./generate-env.sh
```

Estos scripts detectan automáticamente la IP del servidor y un puerto PostgreSQL disponible.

**Para desarrollo local:**
El archivo `.env` ya está incluido con valores por defecto para `localhost`.

### Paso 2: Ejecutar Docker Compose

**Opción A - Script automático (recomendado):**
```bash
# Windows (PowerShell)
.\start-docker.ps1

# Linux/Mac
chmod +x start-docker.sh
./start-docker.sh
```

**Opción B - Docker Compose manual:**
```bash
docker-compose up --build
```

> **Nota:** Si el puerto 5432 está ocupado, puedes especificar otro puerto:
> ```bash
> POSTGRES_HOST_PORT=5433 docker-compose up --build
> ```

### Paso 3: Acceder a la aplicación

- **Frontend:** http://localhost:4200 (o la IP del servidor)
- **Backend API:** http://localhost:5000
- **PostgreSQL:** localhost:5432 (o el puerto detectado) (postgres / ArenaVault2024!)

### Configuración del archivo .env

El archivo `.env` debe contener al menos estas variables:

```env
# Puerto del host para PostgreSQL (si 5432 está ocupado, usa 5433)
POSTGRES_HOST_PORT=5432

# URL del backend API (usada por el frontend para conectarse)
# Para local: http://localhost:5000/api
# Para servidor remoto: http://TU_IP:5000/api
API_URL=http://localhost:5000/api
```

## Servicios

### Frontend (HTML/JS con Nginx) - arenavault-web-ui
- Puerto: 4200
- Contiene una landing page con verificación de conectividad

### Backend (.NET API) - arenavault-api
- Puerto: 5000
- Endpoints:
  - GET /api/health - Health check
  - GET /api/health/database - Verificación de conexión a BD

### Base de Datos (PostgreSQL) - arenavault-postgres
- Puerto: 5432 (o el puerto detectado automáticamente si está ocupado)
- Usuario: postgres
- Password: ArenaVault2024!
- Database: arenavaultdb

## Desarrollo

Para detener los servicios:
```bash
docker-compose down
```

Para ver los logs:
```bash
docker-compose logs -f
```

## 🚀 CI/CD y Deployment

Este proyecto incluye GitHub Actions workflows para:

- **CI (Continuous Integration)**: Build y tests automáticos en cada push/PR
- **CD (Continuous Deployment)**: Deployment automático a Railway o Azure en merge a `main`

### Workflows Disponibles

1. **`.github/workflows/ci.yml`**: Build, test y security scan
2. **`.github/workflows/deploy-railway.yml`**: Deploy a Railway
3. **`.github/workflows/deploy-azure.yml`**: Deploy a Azure

### Configurar Deployment

**Opción 1: Railway (Más rápido)**
```bash
# 1. Crea cuenta en railway.app
# 2. Configura GitHub Secrets:
#    - RAILWAY_TOKEN
#    - RAILWAY_PROJECT_ID
#    - RAILWAY_API_URL
# 3. Push a main → deployment automático
```

**Opción 2: Azure (Producción)**
```bash
# 1. Crea cuenta Azure (con créditos estudiante)
# 2. Configura recursos con Azure CLI
# 3. Configura GitHub Secrets:
#    - AZURE_CREDENTIALS
#    - ACR_USERNAME
#    - ACR_PASSWORD
#    - AZURE_SQL_CONNECTION_STRING
# 4. Push a main → deployment automático
```

## 📚 Documentación Adicional

- [DEPLOYMENT.md](DEPLOYMENT.md) - Troubleshooting y deployment local
- [DEPLOYMENT-GUIDE.md](DEPLOYMENT-GUIDE.md) - Guía paso a paso para Railway y Azure
- [CICD.md](CICD.md) - Comparación detallada de proveedores de hosting
- [ArenaVault-Technical-Design.md](ArenaVault-Technical-Design.md) - Diseño técnico del proyecto

