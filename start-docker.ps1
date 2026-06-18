# Script para iniciar ArenaVault con detección automática de puerto PostgreSQL disponible
# Si el puerto 5432 está ocupado, intentará automáticamente con 5433, 5434, etc.

$ErrorActionPreference = "Stop"

function Test-PortAvailable($port) {
    try {
        $listener = New-Object System.Net.Sockets.TcpListener([System.Net.IPAddress]::Any, $port)
        $listener.Start()
        $listener.Stop()
        return $true
    } catch {
        return $false
    }
}

$startPort = 5432
$maxPort = 5442
$selectedPort = $null

Write-Host "🔍 Buscando puerto disponible para PostgreSQL..."

for ($port = $startPort; $port -le $maxPort; $port++) {
    if (Test-PortAvailable $port) {
        $selectedPort = $port
        Write-Host "✅ Puerto disponible encontrado: $port" -ForegroundColor Green
        break
    } else {
        Write-Host "⚠️ Puerto $port ocupado, probando siguiente..." -ForegroundColor Yellow
    }
}

if (-not $selectedPort) {
    Write-Host "❌ ERROR: No se encontró puerto disponible en el rango $startPort-$maxPort" -ForegroundColor Red
    exit 1
}

$env:POSTGRES_HOST_PORT = $selectedPort

Write-Host "🚀 Iniciando Docker Compose con PostgreSQL en puerto $selectedPort..." -ForegroundColor Cyan
Write-Host "   (La variable de entorno POSTGRES_HOST_PORT=$selectedPort se ha establecido)" -ForegroundColor Gray

# Ejecutar docker-compose con los argumentos recibidos
$args = $args
if ($args.Count -eq 0) {
    docker-compose up --build
} else {
    docker-compose @args
}
