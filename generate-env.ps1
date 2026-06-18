#Requires -Version 5.1
<#
.SYNOPSIS
    Generates the .env file for ArenaVault with the correct API_URL based on the current machine.

.DESCRIPTION
    This script detects the machine's IP address and generates a .env file with the correct
    API_URL for the frontend to communicate with the backend. It also checks for an available
    PostgreSQL port.

.EXAMPLE
    .\generate-env.ps1

.EXAMPLE
    .\generate-env.ps1 -ServerIp "192.168.1.100"
#>

param(
    [string]$ServerIp = "",
    [int]$PostgresPort = 5432,
    [int]$ApiPort = 5000,
    [int]$FrontendPort = 4200
)

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

function Get-LocalIpAddress {
    try {
        $ip = (Get-NetIPAddress -AddressFamily IPv4 | 
               Where-Object { $_.IPAddress -notmatch '^127\.' -and $_.IPAddress -notmatch '^169\.254\.' } | 
               Select-Object -First 1).IPAddress
        return $ip
    } catch {
        # Fallback
        return $env:COMPUTERNAME
    }
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  ArenaVault Environment Generator" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Detect or use provided server IP
if ([string]::IsNullOrEmpty($ServerIp)) {
    $detectedIp = Get-LocalIpAddress
    Write-Host "`nDetected IP address: $detectedIp" -ForegroundColor Yellow
    $useDetected = Read-Host "Use this IP for API_URL? (Y/n)"
    if ($useDetected -eq 'n' -or $useDetected -eq 'N') {
        $ServerIp = Read-Host "Enter the server IP or hostname"
    } else {
        $ServerIp = $detectedIp
    }
}

# Check PostgreSQL port availability
Write-Host "`nChecking PostgreSQL port availability..." -ForegroundColor Cyan
$postgresHostPort = $PostgresPort
$maxAttempts = 10
for ($i = 0; $i -lt $maxAttempts; $i++) {
    $testPort = $PostgresPort + $i
    if (Test-PortAvailable $testPort) {
        $postgresHostPort = $testPort
        Write-Host "  Port $testPort is available" -ForegroundColor Green
        break
    } else {
        Write-Host "  Port $testPort is in use, trying next..." -ForegroundColor Yellow
    }
}

# Construct API URL
$apiUrl = "http://${ServerIp}:${ApiPort}/api"

# Generate .env file
Write-Host "`nGenerating .env file..." -ForegroundColor Cyan

$envContent = @"
# ArenaVault Environment Configuration
# Auto-generated on $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

# ============================================
# PostgreSQL Configuration
# ============================================
POSTGRES_HOST_PORT=$postgresHostPort

# ============================================
# Backend API Configuration
# ============================================
API_URL=$apiUrl

# ============================================
# Database Connection (for reference)
# ============================================
DATABASE_URL=Host=postgres;Database=arenavaultdb;Username=postgres;Password=ArenaVault2024!

# ============================================
# Frontend Configuration
# ============================================
FRONTEND_HOST_PORT=$FrontendPort

# ============================================
# Backend Configuration
# ============================================
BACKEND_HOST_PORT=$ApiPort
"@

$envContent | Out-File -FilePath ".env" -Encoding UTF8

Write-Host "`n.env file created successfully!" -ForegroundColor Green
Write-Host "`nConfiguration Summary:" -ForegroundColor Cyan
Write-Host "  Server IP:       $ServerIp" -ForegroundColor White
Write-Host "  PostgreSQL Port: $postgresHostPort" -ForegroundColor White
Write-Host "  API URL:         $apiUrl" -ForegroundColor White
Write-Host "  Frontend Port:   $FrontendPort" -ForegroundColor White
Write-Host "  API Port:        $ApiPort" -ForegroundColor White

Write-Host "`nNext steps:" -ForegroundColor Cyan
Write-Host "  1. Review the .env file if needed" -ForegroundColor White
Write-Host "  2. Run: docker-compose up --build" -ForegroundColor White
Write-Host "  3. Access the app at: http://${ServerIp}:${FrontendPort}" -ForegroundColor White
