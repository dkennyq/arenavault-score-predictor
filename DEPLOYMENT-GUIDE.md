# Guía de Deployment - ArenaVault

Esta guía explica cómo configurar el deployment automático para ArenaVault.

## 📋 Tabla de Contenidos

- [Opción 1: Railway (Recomendado para inicio rápido)](#opción-1-railway)
- [Opción 2: Azure (Recomendado para producción)](#opción-2-azure)
- [Opción 3: GitHub Actions + Otros Proveedores](#opción-3-otros-proveedores)
- [Comparación de Costos](#comparación-de-costos)

---

## Opción 1: Railway

**✅ Ventajas:**
- Setup rápido (< 10 minutos)
- Excelente soporte para Docker Compose
- Free tier: $5 USD crédito mensual
- Auto-deploy automático desde GitHub
- Variables de ambiente fáciles de configurar

**❌ Desventajas:**
- Después del free tier puede ser costoso
- Free tier limitado (500 horas/mes)

### Paso 1: Crear cuenta en Railway

1. Ve a [railway.app](https://railway.app)
2. Regístrate con tu cuenta de GitHub
3. Autoriza Railway para acceder a tus repositorios

### Paso 2: Crear nuevo proyecto

```bash
# Instalar Railway CLI
npm install -g @railway/cli

# Login
railway login

# Crear nuevo proyecto
railway init

# Link a tu repositorio
railway link
```

### Paso 3: Configurar servicios

Railway necesita 3 servicios:

#### 3.1. SQL Server
```bash
# En Railway Dashboard:
# 1. New Service → Database → SQL Server
# 2. Anota las credenciales generadas
```

#### 3.2. Backend API
```bash
# En Railway Dashboard:
# 1. New Service → GitHub Repo → dkennyq/arenavault-score-predictor
# 2. Root Directory: /backend
# 3. Dockerfile Path: /backend/Dockerfile
```

Variables de ambiente para Backend:
```env
ASPNETCORE_ENVIRONMENT=Production
ConnectionStrings__DefaultConnection=Server=sqlserver.railway.internal;Database=ArenaVaultDB;User Id=sa;Password=${MSSQL_SA_PASSWORD};TrustServerCertificate=True;
```

#### 3.3. Frontend
```bash
# En Railway Dashboard:
# 1. New Service → GitHub Repo → dkennyq/arenavault-score-predictor
# 2. Root Directory: /frontend
# 3. Dockerfile Path: /frontend/Dockerfile
```

Variables de ambiente para Frontend:
```env
API_URL=https://your-api-service.railway.app
```

### Paso 4: Configurar GitHub Actions

1. Ve a tu repositorio en GitHub
2. Settings → Secrets and variables → Actions
3. Agrega los siguientes secrets:

```
RAILWAY_TOKEN=tu-railway-token
RAILWAY_PROJECT_ID=tu-project-id
RAILWAY_API_URL=https://tu-api.railway.app
```

Para obtener el token:
```bash
railway login
railway whoami --token
```

### Paso 5: Activar auto-deploy

En Railway Dashboard:
1. Cada servicio → Settings → Service
2. Deploy Triggers → Enable GitHub Auto Deploy
3. Branch: `main`
4. ✅ Deploy on push to main

### Paso 6: Probar deployment

```bash
# Hacer un cambio y push a main
git add .
git commit -m "Test Railway deployment"
git push origin main

# Railway automáticamente detectará el push y hará deploy
```

### Verificar deployment:
1. Railway Dashboard → Deployments
2. Ver logs en tiempo real
3. Abrir la URL pública del frontend

---

## Opción 2: Azure

**✅ Ventajas:**
- Stack completo Microsoft (.NET + SQL Server)
- Créditos para estudiantes: $100 USD por 12 meses
- Integración nativa con GitHub Actions
- Mejor para producción y escalabilidad

**❌ Desventajas:**
- Configuración inicial más compleja
- Curva de aprendizaje pronunciada

### Paso 1: Crear cuenta Azure

1. Ve a [azure.microsoft.com/students](https://azure.microsoft.com/students) (si eres estudiante)
2. O [portal.azure.com](https://portal.azure.com) para cuenta regular
3. Activa los $100 USD de crédito gratuito

### Paso 2: Instalar Azure CLI

```bash
# Windows (PowerShell)
winget install Microsoft.AzureCLI

# Verificar instalación
az --version

# Login
az login
```

### Paso 3: Crear recursos en Azure

```bash
# Variables
$RESOURCE_GROUP="arenavault-rg"
$LOCATION="eastus"
$ACR_NAME="arenavaultacr"
$SQL_SERVER="arenavault-sql"
$SQL_DB="ArenaVaultDB"

# Crear Resource Group
az group create --name $RESOURCE_GROUP --location $LOCATION

# Crear Azure Container Registry
az acr create `
  --resource-group $RESOURCE_GROUP `
  --name $ACR_NAME `
  --sku Basic `
  --admin-enabled true

# Crear Azure SQL Server
az sql server create `
  --resource-group $RESOURCE_GROUP `
  --name $SQL_SERVER `
  --admin-user sqladmin `
  --admin-password "ArenaVault2024!"

# Crear Azure SQL Database
az sql db create `
  --resource-group $RESOURCE_GROUP `
  --server $SQL_SERVER `
  --name $SQL_DB `
  --service-objective Basic

# Configurar firewall (permitir Azure services)
az sql server firewall-rule create `
  --resource-group $RESOURCE_GROUP `
  --server $SQL_SERVER `
  --name AllowAzureServices `
  --start-ip-address 0.0.0.0 `
  --end-ip-address 0.0.0.0
```

### Paso 4: Crear Container Apps Environment

```bash
# Instalar extensión de Container Apps
az extension add --name containerapp --upgrade

# Crear Container Apps Environment
az containerapp env create `
  --name arenavault-env `
  --resource-group $RESOURCE_GROUP `
  --location $LOCATION

# Crear Container App para Backend
az containerapp create `
  --name arenavault-api `
  --resource-group $RESOURCE_GROUP `
  --environment arenavault-env `
  --image mcr.microsoft.com/dotnet/aspnet:10.0 `
  --target-port 5000 `
  --ingress external `
  --env-vars "ASPNETCORE_ENVIRONMENT=Production"

# Crear Container App para Frontend
az containerapp create `
  --name arenavault-web-ui `
  --resource-group $RESOURCE_GROUP `
  --environment arenavault-env `
  --image nginx:alpine `
  --target-port 80 `
  --ingress external
```

### Paso 5: Configurar GitHub Secrets para Azure

1. Crear Service Principal:
```bash
az ad sp create-for-rbac `
  --name "arenavault-github-actions" `
  --role contributor `
  --scopes /subscriptions/{subscription-id}/resourceGroups/$RESOURCE_GROUP `
  --sdk-auth
```

2. Copiar el JSON output y agregarlo a GitHub Secrets como `AZURE_CREDENTIALS`

3. Obtener credenciales del ACR:
```bash
# Username
az acr credential show --name $ACR_NAME --query "username" -o tsv

# Password
az acr credential show --name $ACR_NAME --query "passwords[0].value" -o tsv
```

4. Agregar a GitHub Secrets:
```
AZURE_CREDENTIALS={json-from-step-1}
ACR_USERNAME=username-from-step-3
ACR_PASSWORD=password-from-step-3
AZURE_SQL_CONNECTION_STRING=Server=tcp:arenavault-sql.database.windows.net,1433;Database=ArenaVaultDB;User Id=sqladmin;Password=ArenaVault2024!;TrustServerCertificate=True;
```

### Paso 6: Activar workflow de Azure

El archivo `.github/workflows/deploy-azure.yml` ya está configurado. Solo necesitas:

1. Hacer push a `main`
2. GitHub Actions automáticamente:
   - Construirá las imágenes Docker
   - Las subirá a Azure Container Registry
   - Desplegará a Azure Container Apps
   - Ejecutará health checks

### Verificar deployment:

```bash
# Obtener URL del API
az containerapp show `
  --name arenavault-api `
  --resource-group $RESOURCE_GROUP `
  --query properties.configuration.ingress.fqdn -o tsv

# Obtener URL del Frontend
az containerapp show `
  --name arenavault-web-ui `
  --resource-group $RESOURCE_GROUP `
  --query properties.configuration.ingress.fqdn -o tsv

# Test health check
curl https://your-api-url.azurecontainerapps.io/api/health
```

---

## Opción 3: Otros Proveedores

### Fly.io
- **Free tier generoso**: 3 VMs compartidas gratis
- **Limitación**: No soporta SQL Server nativamente (usar PostgreSQL)

### Render
- **Free tier**: Web services gratis
- **Limitación**: Se "duerme" después de inactividad
- **Limitación**: SQL Server requiere plan pago

### Heroku
- **Nota**: Ya no tiene free tier desde Nov 2022
- No recomendado para nuevos proyectos gratuitos

---

## Comparación de Costos

### Desarrollo/Testing (primeros 6 meses)

| Proveedor | Costo Mensual | Free Tier | Notas |
|-----------|--------------|-----------|-------|
| **Railway** | $5-20 | $5 crédito | Más simple, bueno para demos |
| **Azure** | $0 | $100 crédito (12 meses estudiantes) | Mejor para producción |
| **Fly.io** | $0-10 | 3 VMs gratis | Requiere PostgreSQL |
| **Render** | $7+ | Web service gratis, DB pago | Se duerme en inactividad |

### Producción (después de 6 meses)

| Proveedor | Costo Mensual Estimado | Escalabilidad | Soporte .NET + SQL |
|-----------|------------------------|---------------|-------------------|
| **Railway** | $20-50 | Media | ✅ Excelente |
| **Azure** | $30-100 | Alta | ✅ Nativo |
| **Fly.io** | $15-40 | Media | ⚠️ Solo PostgreSQL |
| **Render** | $25-60 | Media | ⚠️ SQL Server limitado |

---

## Recomendación Final

### Para empezar ahora (Demo/MVP):
**🚀 Railway**
- Más rápido de configurar
- Perfecto para mostrar el proyecto
- Suficiente para fase inicial

### Para producción seria:
**☁️ Azure**
- Créditos gratuitos para estudiantes
- Stack completo Microsoft
- Escalable y profesional

### Plan sugerido:
1. **Fase 1 (0-3 meses)**: Railway para desarrollo
2. **Fase 2 (3-6 meses)**: Migrar a Azure cuando el proyecto madure
3. **Fase 3 (6+ meses)**: Azure con plan optimizado según uso real

---

## Próximos Pasos

1. ✅ Elige un proveedor (Railway o Azure)
2. ✅ Sigue los pasos de configuración arriba
3. ✅ Configura los GitHub Secrets
4. ✅ Haz push a `main` para activar el deployment
5. ✅ Verifica que los health checks pasen
6. ✅ Prueba la aplicación en producción

## Soporte

Si encuentras problemas:
1. Revisa los logs en GitHub Actions
2. Revisa los logs del proveedor (Railway Dashboard o Azure Portal)
3. Verifica que todas las variables de ambiente estén configuradas
4. Consulta `DEPLOYMENT.md` para troubleshooting local

---

**¿Preguntas?** Abre un issue en el repositorio o consulta la documentación oficial de cada proveedor.
