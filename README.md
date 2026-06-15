# ArenaVault Score Predictor

Sistema de predicción de puntajes para Arena of Valor.

## Stack Tecnológico

- **Frontend**: HTML/JavaScript/CSS (interfaz simple y rápida)
- **Backend**: .NET 10 Web API con Entity Framework Core
- **Base de Datos**: SQL Server 2022
- **Containerización**: Docker & Docker Compose
- **CI/CD**: GitHub Actions con deployment automático
- **Deployment**: Soporta Railway y Azure

## Requisitos Previos

- Docker Desktop instalado
- Docker Compose instalado

## Inicio Rápido

1. Clonar el repositorio
2. Ejecutar Docker Compose:

```bash
docker-compose up --build
```

3. Acceder a la aplicación:
   - Frontend: http://localhost:4200
   - Backend API: http://localhost:5000
   - SQL Server: localhost:1433 (sa / ArenaVault2024!)

## Servicios

### Frontend (HTML/JS con Nginx) - arenavault-web-ui
- Puerto: 4200
- Contiene una landing page con verificación de conectividad

### Backend (.NET API) - arenavault-api
- Puerto: 5000
- Endpoints:
  - GET /api/health - Health check
  - GET /api/health/database - Verificación de conexión a BD

### Base de Datos (SQL Server) - arenavault-sqlserver
- Puerto: 1433
- Usuario: sa
- Password: ArenaVault2024!
- Database: ArenaVaultDB

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

