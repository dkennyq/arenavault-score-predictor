# Guía de CI/CD y Deployment - ArenaVault

## Opciones de Hosting y Deployment

### Comparativa de Proveedores

| Característica | Railway | Azure | Fly.io | Render |
|---------------|---------|-------|--------|--------|
| **Free Tier** | $5 USD crédito/mes | $100 USD estudiantes/año | 3 VMs gratis | Web services gratis |
| **Docker Support** | ⭐⭐⭐⭐⭐ Nativo | ⭐⭐⭐⭐ Container Apps | ⭐⭐⭐⭐⭐ Nativo | ⭐⭐⭐⭐ Nativo |
| **.NET Support** | ⭐⭐⭐⭐⭐ Excelente | ⭐⭐⭐⭐⭐ Nativo | ⭐⭐⭐⭐ Via Docker | ⭐⭐⭐⭐ Via Docker |
| **SQL Server** | ⭐⭐⭐ Via Docker | ⭐⭐⭐⭐⭐ Nativo Azure SQL | ❌ No soportado | ❌ No soportado |
| **Setup Complexity** | ⭐⭐⭐⭐⭐ Muy simple | ⭐⭐⭐ Complejo | ⭐⭐⭐⭐ Simple | ⭐⭐⭐⭐ Simple |
| **GitHub Integration** | ⭐⭐⭐⭐⭐ Automático | ⭐⭐⭐⭐⭐ GitHub Actions | ⭐⭐⭐⭐ Via GitHub Actions | ⭐⭐⭐⭐⭐ Automático |
| **Pricing (después de free)** | 💰💰💰 $5-20+/mes | 💰💰 Pay-as-you-go | 💰💰 Pay-as-you-go | 💰💰 $7-25+/mes |
| **Best For** | Dev/Testing rápido | Producción empresarial | Apps modernas | Startups |

---

## Recomendación por Caso de Uso

### 🚀 Para Comenzar Rápido (Desarrollo/Testing)
**Opción 1: Railway**
- Setup en 10 minutos
- Ideal para demostrar el proyecto
- $5 USD/mes es suficiente para testing
- Fácil migrar después si es necesario

### 🏢 Para Producción (Largo Plazo)
**Opción 1: Azure**
- Stack Microsoft completo (.NET + SQL Server)
- Créditos para estudiantes/startups
- Escalabilidad profesional
- Mejor opción para proyectos serios

### 💡 Alternativa Económica
**Opción 2: Fly.io + PostgreSQL**
- Free tier generoso
- Cambiar SQL Server por PostgreSQL
- Bueno para MVP y startups
- Menos configuración que Azure

---

## 1. Railway Deployment

### A. Configuración Inicial

1. **Crear cuenta en Railway:**
   - Ir a https://railway.app
   - Sign up con GitHub

2. **Crear nuevo proyecto:**
   ```bash
   # Desde Railway dashboard
   New Project > Deploy from GitHub repo > Seleccionar arenavault-score-predictor
   ```

3. **Configurar servicios:**

   **SQL Server Service:**
   - Add Service > Docker Image
   - Image: `mcr.microsoft.com/mssql/server:2022-latest`
   - Variables:
     - `ACCEPT_EULA=Y`
     - `SA_PASSWORD` (generar contraseña segura)
     - `MSSQL_PID=Developer`

   **Backend API Service:**
   - Add Service > GitHub Repo > backend/
   - Variables:
     - `ASPNETCORE_ENVIRONMENT=Production`
     - `ConnectionStrings__DefaultConnection` (apuntar a SQL Server)

   **Frontend Service:**
   - Add Service > GitHub Repo > frontend/
   - Settings > Networking > Generate Domain

### B. Variables de Ambiente en Railway

```
# SQL Server
ACCEPT_EULA=Y
SA_PASSWORD=<CONTRASEÑA_SEGURA>
MSSQL_PID=Developer

# Backend API
ASPNETCORE_ENVIRONMENT=Production
ASPNETCORE_URLS=http://+:5000
ConnectionStrings__DefaultConnection=Server=sqlserver.railway.internal;Database=ArenaVaultDB;User Id=sa;Password=<CONTRASEÑA_SEGURA>;TrustServerCertificate=True;

# Frontend
API_URL=https://arenavault-api.railway.app
```

### C. Auto-Deployment

Railway detecta automáticamente los cambios en `main` y hace deployment automático.

**Configuración adicional (railway.json):**
```json
{
  "$schema": "https://railway.app/railway.schema.json",
  "build": {
    "builder": "DOCKERFILE",
    "dockerfilePath": "Dockerfile"
  },
  "deploy": {
    "startCommand": "dotnet ArenaVault.API.dll",
    "healthcheckPath": "/api/health",
    "healthcheckTimeout": 100
  }
}
```

---

## 2. Azure Deployment

### A. Requisitos Previos

1. **Cuenta Azure:**
   - Crear cuenta en https://azure.microsoft.com
   - Si eres estudiante: https://azure.microsoft.com/free/students/

2. **Azure CLI instalado:**
   ```bash
   # Windows (PowerShell)
   winget install Microsoft.AzureCLI
   
   # Verificar instalación
   az --version
   ```

3. **Login a Azure:**
   ```bash
   az login
   ```

### B. Crear Recursos en Azure

```bash
# Variables
RESOURCE_GROUP="arenavault-rg"
LOCATION="eastus"
ACR_NAME="arenavaultacr"
SQL_SERVER="arenavault-sql"
SQL_DB="ArenaVaultDB"

# 1. Crear Resource Group
az group create --name $RESOURCE_GROUP --location $LOCATION

# 2. Crear Azure Container Registry
az acr create --resource-group $RESOURCE_GROUP \
  --name $ACR_NAME --sku Basic

# 3. Crear Azure SQL Server
az sql server create --name $SQL_SERVER \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --admin-user sqladmin \
  --admin-password <CONTRASEÑA_SEGURA>

# 4. Crear SQL Database
az sql db create --resource-group $RESOURCE_GROUP \
  --server $SQL_SERVER \
  --name $SQL_DB \
  --service-objective S0

# 5. Configurar firewall de SQL Server
az sql server firewall-rule create \
  --resource-group $RESOURCE_GROUP \
  --server $SQL_SERVER \
  --name AllowAzureServices \
  --start-ip-address 0.0.0.0 \
  --end-ip-address 0.0.0.0

# 6. Crear Azure Container Apps Environment
az containerapp env create \
  --name arenavault-env \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION

# 7. Crear Container App para Backend
az containerapp create \
  --name arenavault-api \
  --resource-group $RESOURCE_GROUP \
  --environment arenavault-env \
  --image $ACR_NAME.azurecr.io/arenavault-api:latest \
  --target-port 5000 \
  --ingress external \
  --registry-server $ACR_NAME.azurecr.io

# 8. Crear Container App para Frontend
az containerapp create \
  --name arenavault-web-ui \
  --resource-group $RESOURCE_GROUP \
  --environment arenavault-env \
  --image $ACR_NAME.azurecr.io/arenavault-web-ui:latest \
  --target-port 80 \
  --ingress external \
  --registry-server $ACR_NAME.azurecr.io
```

### C. GitHub Actions para Azure

Ver archivo `.github/workflows/deploy-azure.yml` (se creará en siguiente paso)

---

## 3. GitHub Actions Setup

### A. Estructura de Workflows

```
.github/
└── workflows/
    ├── ci.yml              # Build y test en cada PR/push
    ├── deploy-railway.yml  # Deploy a Railway en merge a main
    └── deploy-azure.yml    # Deploy a Azure en merge a main (alternativa)
```

### B. Secrets Requeridos

**Para Railway:**
- `RAILWAY_TOKEN` - Token de API de Railway

**Para Azure:**
- `AZURE_CREDENTIALS` - Service Principal credentials
- `ACR_USERNAME` - Azure Container Registry username
- `ACR_PASSWORD` - Azure Container Registry password
- `AZURE_SQL_CONNECTION_STRING` - Connection string de Azure SQL

**Cómo configurar secrets:**
```bash
# En GitHub: Settings > Secrets and variables > Actions > New repository secret
```

---

## 4. Flujo de Trabajo (Workflow)

### Flujo Típico de Desarrollo

```
1. Desarrollador crea feature branch
   ↓
2. Hace cambios y commits
   ↓
3. Push a GitHub
   ↓
4. GitHub Actions ejecuta CI (build + test)
   ↓
5. Si CI pasa, crear Pull Request
   ↓
6. Code review y aprobación
   ↓
7. Merge a main
   ↓
8. GitHub Actions ejecuta CD (deployment)
   ↓
9. Deployment automático a Railway/Azure
   ↓
10. Health checks post-deployment
    ↓
11. Notificación de éxito/fallo
```

---

## 5. Monitoreo y Logs

### Railway
```bash
# Ver logs en tiempo real
railway logs --service arenavault-api
railway logs --service arenavault-web-ui
```

### Azure
```bash
# Ver logs de Container App
az containerapp logs show \
  --name arenavault-api \
  --resource-group arenavault-rg \
  --follow

# Ver métricas
az monitor metrics list \
  --resource-group arenavault-rg \
  --resource arenavault-api
```

---

## 6. Costos Estimados

### Railway (Después del Free Tier)
- **Hobby Plan:** $5 USD/mes por servicio
- **Pro Plan:** $20 USD/mes (incluye múltiples servicios)
- **Estimado para ArenaVault:** $15-20 USD/mes

### Azure (Después de Créditos)
- **Container Apps:** ~$5-15 USD/mes
- **Azure SQL Database (S0):** ~$15 USD/mes
- **Container Registry:** ~$5 USD/mes
- **Estimado Total:** $25-35 USD/mes

### Fly.io
- **3 VMs gratis** (suficiente para comenzar)
- **Postgres gratis** (hasta 3GB)
- **Estimado:** $0-10 USD/mes inicialmente

---

## 7. Próximos Pasos

1. ✅ Decidir proveedor (Railway recomendado para comenzar)
2. ⬜ Crear cuenta en el proveedor elegido
3. ⬜ Configurar GitHub Actions
4. ⬜ Configurar secrets en GitHub
5. ⬜ Hacer primer deployment
6. ⬜ Verificar funcionamiento
7. ⬜ Configurar dominio personalizado (opcional)

---

## 8. Troubleshooting

### Deployment Falla en Railway

**Error: Container failed to start**
```bash
# Verificar logs
railway logs --service arenavault-api

# Verificar variables de ambiente
railway variables
```

**Error: Database connection failed**
- Verificar ConnectionString
- Verificar que SQL Server esté corriendo
- Verificar credenciales

### Deployment Falla en Azure

**Error: Image pull failed**
```bash
# Verificar que la imagen existe en ACR
az acr repository list --name $ACR_NAME
```

**Error: Health check failed**
- Verificar que el endpoint /api/health responde
- Verificar puerto configurado (5000 para backend)

---

## 9. Recursos Adicionales

- [Railway Documentation](https://docs.railway.app/)
- [Azure Container Apps Documentation](https://learn.microsoft.com/azure/container-apps/)
- [GitHub Actions Documentation](https://docs.github.com/actions)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
