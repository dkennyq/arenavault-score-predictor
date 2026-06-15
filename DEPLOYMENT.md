# Guía de Despliegue - ArenaVault Score Predictor

## Estructura del Proyecto

```
arenavault-score-predictor/
├── backend/
│   ├── ArenaVault.API/
│   │   ├── Data/
│   │   │   └── ArenaVaultDbContext.cs
│   │   ├── Models/
│   │   │   └── HealthResponse.cs
│   │   ├── Program.cs
│   │   ├── appsettings.json
│   │   └── ArenaVault.API.csproj
│   ├── Dockerfile
│   └── .dockerignore
├── frontend/
│   ├── index.html
│   ├── nginx.conf
│   └── Dockerfile
├── docker-compose.yml
├── .gitignore
└── README.md
```

## Stack Tecnológico

### Backend (.NET 10)
- **Framework**: ASP.NET Core 10.0 Web API
- **ORM**: Entity Framework Core 10.0
- **Base de Datos**: SQL Server 2022
- **Puerto**: 5000

#### Endpoints Disponibles:

1. **GET /api/health**
   - Verifica que el backend está funcionando
   - Respuesta: `{ status, message, timestamp }`

2. **GET /api/health/database**
   - Verifica la conexión con SQL Server
   - Crea la base de datos si no existe
   - Respuesta: `{ status, message, timestamp }`

### Frontend (HTML/JavaScript con Nginx)
- **Servidor Web**: Nginx (Alpine Linux)
- **Puerto**: 4200
- **Características**:
  - Landing page responsive
  - Botones para verificar backend y base de datos
  - Interfaz moderna con gradientes
  - Mensajes de estado claros

### Base de Datos (SQL Server 2022)
- **Imagen**: mcr.microsoft.com/mssql/server:2022-latest
- **Puerto**: 1433
- **Usuario**: sa
- **Contraseña**: ArenaVault2024!
- **Database**: ArenaVaultDB

## Configuración de Docker Compose

### Servicios Definidos:

1. **sqlserver**
   - Health check configurado
   - Volumen persistente para datos
   - Variables de ambiente para configuración

2. **backend**
   - Depende de que sqlserver esté healthy
   - Connection string configurada
   - CORS habilitado para desarrollo

3. **frontend**
   - Depende del backend
   - Nginx configurado para servir archivos estáticos
   - Proxy configurado si es necesario

### Red y Volúmenes:

- **Red**: `arenavault-network` (bridge)
- **Volumen**: `sqlserver-data` (persistencia de datos)

## Comandos de Docker Compose

### Iniciar los servicios:
```bash
docker-compose up --build -d
```

### Ver los logs:
```bash
docker-compose logs -f
```

### Ver logs de un servicio específico:
```bash
docker-compose logs -f backend
docker-compose logs -f frontend
docker-compose logs -f sqlserver
```

### Detener los servicios:
```bash
docker-compose down
```

### Detener y eliminar volúmenes:
```bash
docker-compose down -v
```

### Reconstruir un servicio específico:
```bash
docker-compose up --build -d backend
```

### Ver el estado de los servicios:
```bash
docker-compose ps
```

## Verificación de Funcionamiento

### 1. Verificar que los contenedores están corriendo:
```bash
docker ps
```

Deberías ver 3 contenedores:
- arenavault-sqlserver
- arenavault-backend
- arenavault-frontend

### 2. Verificar el backend directamente:
```bash
curl http://localhost:5000/api/health
```

### 3. Verificar la conexión a la base de datos:
```bash
curl http://localhost:5000/api/health/database
```

### 4. Abrir el frontend:
```
http://localhost:4200
```

## Troubleshooting

### El backend no puede conectarse a SQL Server:

1. Verificar que el contenedor de SQL Server está healthy:
```bash
docker inspect arenavault-sqlserver | grep -A 10 Health
```

2. Ver los logs de SQL Server:
```bash
docker-compose logs sqlserver
```

3. Verificar la conexión desde el backend:
```bash
docker exec -it arenavault-backend bash
# Dentro del contenedor, verificar variables de ambiente
env | grep ConnectionStrings
```

### Error de CORS en el frontend:

El backend ya tiene CORS configurado para permitir cualquier origen en desarrollo. Si aún hay problemas:

1. Verificar que el backend esté corriendo
2. Verificar la URL del API en el frontend (debe ser http://localhost:5000)

### SQL Server no arranca:

SQL Server requiere al menos 2GB de RAM. Verificar:

```bash
docker stats
```

### Puerto ya en uso:

Si algún puerto (1433, 5000, 4200) ya está en uso, puedes cambiarlos en el docker-compose.yml:

```yaml
ports:
  - "PUERTO_EXTERNO:PUERTO_INTERNO"
```

## Desarrollo Local (sin Docker)

### Backend:
```bash
cd backend/ArenaVault.API
dotnet restore
dotnet run
```

### Frontend:
Abre `frontend/index.html` directamente en el navegador o usa un servidor HTTP simple:
```bash
cd frontend
python -m http.server 4200
# o
npx http-server -p 4200
```

### Base de Datos:
Instala SQL Server localmente o usa SQL Server Express.

## Próximos Pasos

1. ✅ Stack básico funcionando
2. 🔄 Agregar modelos de datos (Matches, Players, etc.)
3. 🔄 Implementar endpoints de API para predicciones
4. 🔄 Desarrollar frontend con Angular completo
5. 🔄 Implementar algoritmo de predicción de puntajes
6. 🔄 Agregar autenticación y autorización
7. 🔄 Implementar tests unitarios e integración
8. 🔄 Configurar CI/CD

## Notas Importantes

- **Seguridad**: La contraseña de SQL Server está hardcodeada para desarrollo. En producción, usa secrets o variables de ambiente seguras.
- **CORS**: Está configurado para permitir cualquier origen en desarrollo. Restringir en producción.
- **Volúmenes**: Los datos de SQL Server persisten entre reinicios. Usa `docker-compose down -v` para eliminar datos.
- **Health Checks**: El backend espera a que SQL Server esté healthy antes de iniciar.
