# ArenaVault Score Predictor

Sistema de predicción de puntajes para Arena of Valor.

## Stack Tecnológico

- **Frontend**: Angular 17+
- **Backend**: .NET 8 Web API
- **Base de Datos**: SQL Server 2022
- **Containerización**: Docker & Docker Compose

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

### Frontend (Angular)
- Puerto: 4200
- Contiene una landing page con verificación de conectividad

### Backend (.NET API)
- Puerto: 5000
- Endpoints:
  - GET /api/health - Health check
  - GET /api/health/database - Verificación de conexión a BD

### Base de Datos (SQL Server)
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
