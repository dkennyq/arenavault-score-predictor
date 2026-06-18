# Railway Setup - PostgreSQL Version

## ✅ Completado
- Railway CLI instalado
- Login exitoso (devkennyq)
- Proyecto creado: `arenavault-test`
- Project ID: `dd0dadd2-8770-408e-ad6a-bd13458718c5`
- **Migrado a PostgreSQL** (Railway compatible)

---

## 🎯 Siguiente: Configurar 3 Servicios

Railway no soporta la creación de servicios completos vía CLI. Debes hacerlo desde el Dashboard web.

### **Abre el Dashboard:**
https://railway.app/project/dd0dadd2-8770-408e-ad6a-bd13458718c5

---

## Servicio 1: PostgreSQL Database 🗄️

1. En Railway Dashboard, click **"+ New"**
2. Selecciona **"Database"** → **"Add PostgreSQL"**
3. Railway creará el servicio automáticamente
4. **IMPORTANTE:** Railway automáticamente inyecta estas variables:
   - `PGHOST` - hostname de la base de datos
   - `PGPORT` - puerto (5432)
   - `PGDATABASE` - nombre de la base de datos
   - `PGUSER` - usuario
   - `PGPASSWORD` - password
   - `DATABASE_URL` - connection string completa

**Nombre sugerido:** `arenavault-postgres`

**No necesitas anotar nada** - Railway maneja las credenciales automáticamente.

---

## Servicio 2: Backend API (.NET) 🔧

1. En Railway Dashboard, click **"+ New"**
2. Selecciona **"GitHub Repo"**
3. Busca y selecciona: `dkennyq/arenavault-score-predictor`
4. Railway preguntará qué servicio crear. Configura:

### Settings del Servicio:
- **Service Name:** `arenavault-api`
- **Branch:** `dkennyq/docker-setup-inicial`
- **Root Directory:** `/backend`
- **Builder:** Dockerfile
- **Dockerfile Path:** `/backend/Dockerfile`

### Variables de Ambiente:
Ve a la pestaña **"Variables"** y agrega:

```env
ASPNETCORE_ENVIRONMENT=Production

ASPNETCORE_URLS=http://0.0.0.0:5000

ConnectionStrings__DefaultConnection=${DATABASE_URL}
```

**Clave:** Railway automáticamente compartirá la variable `DATABASE_URL` del servicio PostgreSQL.

### Conectar servicios:
1. En la pestaña **"Variables"** del backend
2. Click en **"+ New Variable"** → **"Add Reference"**
3. Selecciona el servicio PostgreSQL
4. Railway agregará automáticamente todas las variables `PG*` y `DATABASE_URL`

### Networking:
1. Ve a **"Settings"** → **"Networking"**
2. Habilita **"Generate Domain"**
3. **COPIA LA URL PÚBLICA** (ej: `arenavault-api-production.up.railway.app`)
4. Anótala para GitHub Secrets

### Port:
- Railway detectará automáticamente el puerto 5000 del Dockerfile

---

## Servicio 3: Frontend (HTML/Nginx) 🎨

1. En Railway Dashboard, click **"+ New"**
2. Selecciona **"GitHub Repo"**
3. Busca y selecciona: `dkennyq/arenavault-score-predictor`

### Settings del Servicio:
- **Service Name:** `arenavault-web-ui`
- **Branch:** `dkennyq/docker-setup-inicial`
- **Root Directory:** `/frontend`
- **Builder:** Dockerfile
- **Dockerfile Path:** `/frontend/Dockerfile`

### Networking:
1. Ve a **"Settings"** → **"Networking"**
2. Habilita **"Generate Domain"**
3. **COPIA LA URL PÚBLICA** (ej: `arenavault-web-ui-production.up.railway.app`)

### Port:
- Railway detectará automáticamente el puerto 80 de Nginx

---

## 📝 Información a Recopilar

Mientras configuras, anota estos valores:

```
✅ Project ID: dd0dadd2-8770-408e-ad6a-bd13458718c5

⬜ Backend API URL: https://_____________________.up.railway.app

⬜ Frontend URL: https://_____________________.up.railway.app

⬜ Railway Token: (obtener con `railway whoami --token`)
```

---

## ⚠️ Ventajas de PostgreSQL en Railway

✅ **Nativo:** Railway tiene soporte nativo para PostgreSQL  
✅ **Auto-config:** Variables de ambiente automáticas  
✅ **Backups:** Incluidos en el plan  
✅ **Conexiones:** Railway maneja el connection pooling  
✅ **Precio:** Incluido en el free tier de Railway

---

## 🚀 Después de Crear los 3 Servicios

1. **Espera a que los servicios desplieguen** (primera vez 3-5 min)
2. **Verifica los logs** de cada servicio
3. **Prueba el backend:**
   ```powershell
   curl https://tu-backend-url.up.railway.app/api/health
   ```
   Debería responder: `{"status":"Healthy","timestamp":"..."}`

4. **Prueba el frontend:**
   - Abre: `https://tu-frontend-url.up.railway.app`
   - Click en los botones de verificación

---

## 💡 Tips PostgreSQL

- **Connection String:** Railway inyecta automáticamente `DATABASE_URL` en formato PostgreSQL
- **Migrations:** EF Core funcionará igual con PostgreSQL
- **Performance:** PostgreSQL es más rápido que SQL Server para aplicaciones web
- **Free Tier:** 512MB RAM, 1GB storage incluido

---

**¿Listo?** Avísame cuando hayas creado los 3 servicios para continuar con GitHub Secrets y el PR. 🚀

1. En Railway Dashboard, click **"+ New"**
2. Selecciona **"Database"** → **"Add SQL Server"**
3. Railway creará el servicio automáticamente
4. **IMPORTANTE:** Anota estas credenciales (las necesitaremos):
   - Ve a la pestaña **"Variables"** del servicio SQL Server
   - Busca y copia:
     - `MSSQL_SA_PASSWORD` (password del SA)
     - `MSSQLSERVER_HOST` (hostname interno)
     - `MSSQLSERVER_PORT` (debería ser 1433)

**Nombre sugerido:** `arenavault-sqlserver`

---

## Servicio 2: Backend API (.NET) 🔧

1. En Railway Dashboard, click **"+ New"**
2. Selecciona **"GitHub Repo"**
3. Busca y selecciona: `dkennyq/arenavault-score-predictor`
4. Railway preguntará qué servicio crear. Configura:

### Settings del Servicio:
- **Service Name:** `arenavault-api`
- **Branch:** `dkennyq/docker-setup-inicial` (IMPORTANTE: usar este branch por ahora)
- **Root Directory:** `/backend`
- **Builder:** Dockerfile
- **Dockerfile Path:** `/backend/Dockerfile`

### Variables de Ambiente:
Ve a la pestaña **"Variables"** y agrega estas 3 variables:

```env
ASPNETCORE_ENVIRONMENT=Production

ASPNETCORE_URLS=http://0.0.0.0:5000

ConnectionStrings__DefaultConnection=Server=${MSSQLSERVER_HOST};Database=ArenaVaultDB;User Id=sa;Password=${MSSQL_SA_PASSWORD};TrustServerCertificate=True;
```

**NOTA:** Railway automáticamente reemplazará `${MSSQLSERVER_HOST}` y `${MSSQL_SA_PASSWORD}` con los valores del servicio SQL Server si los referencias correctamente.

### Networking:
1. Ve a **"Settings"** → **"Networking"**
2. Habilita **"Generate Domain"** o **"Public Networking"**
3. **COPIA LA URL PÚBLICA** que Railway genera (ej: `arenavault-api-production.up.railway.app`)
4. Anótala - la necesitaremos para GitHub Secrets

### Port:
1. Ve a **"Settings"** → **"Deploy"**
2. Asegúrate que el puerto sea **5000** (Railway debería detectarlo automáticamente del Dockerfile)

---

## Servicio 3: Frontend (HTML/Nginx) 🎨

1. En Railway Dashboard, click **"+ New"**
2. Selecciona **"GitHub Repo"**
3. Busca y selecciona: `dkennyq/arenavault-score-predictor`

### Settings del Servicio:
- **Service Name:** `arenavault-web-ui`
- **Branch:** `dkennyq/docker-setup-inicial` (IMPORTANTE: usar este branch por ahora)
- **Root Directory:** `/frontend`
- **Builder:** Dockerfile
- **Dockerfile Path:** `/frontend/Dockerfile`

### Networking:
1. Ve a **"Settings"** → **"Networking"**
2. Habilita **"Generate Domain"** o **"Public Networking"**
3. **COPIA LA URL PÚBLICA** (ej: `arenavault-web-ui-production.up.railway.app`)

### Port:
1. Ve a **"Settings"** → **"Deploy"**
2. El puerto debería ser **80** (detectado del nginx.conf)

---

## 📝 Información a Recopilar

Mientras configuras, anota estos valores:

```
✅ Project ID: dd0dadd2-8770-408e-ad6a-bd13458718c5

⬜ MSSQL_SA_PASSWORD: _____________________

⬜ Backend API URL: https://_____________________.up.railway.app

⬜ Frontend URL: https://_____________________.up.railway.app

⬜ Railway Token: (obtener con `railway whoami --token`)
```

---

## ⚠️ Importante: Referencias entre Servicios

Para que el Backend se conecte a SQL Server, Railway usa **service references**:

1. En el servicio **arenavault-api**, ve a **"Variables"**
2. Cuando agregues `ConnectionStrings__DefaultConnection`, Railway debería ofrecer autocompletado para `${MSSQLSERVER_HOST}`
3. Si no aparece, usa el hostname interno: `sqlserver.railway.internal` o el service name que Railway asignó

---

## 🚀 Después de Crear los 3 Servicios

1. **Espera a que los servicios desplieguen** (primera vez puede tomar 3-5 minutos)
2. **Verifica los logs** de cada servicio para asegurarte que no haya errores
3. **Prueba el backend:**
   ```powershell
   curl https://tu-backend-url.up.railway.app/api/health
   ```
   Debería responder: `{"status":"Healthy","timestamp":"..."}`

4. **Prueba el frontend:**
   - Abre en el navegador: `https://tu-frontend-url.up.railway.app`
   - Click en los botones de verificación

---

## 💡 Tips

- **Si SQL Server tarda mucho:** Es normal, SQL Server es pesado. Puede tomar 2-3 minutos en iniciar.
- **Si el backend falla al conectar:** Revisa que las variables de ambiente estén correctas y que SQL Server esté running.
- **Si el frontend no encuentra el API:** Verifica que la URL del backend sea correcta y esté accesible públicamente.

---

**¿Listo?** Avísame cuando hayas creado los 3 servicios y te ayudo con los siguientes pasos (GitHub Secrets y PR). 🚀
