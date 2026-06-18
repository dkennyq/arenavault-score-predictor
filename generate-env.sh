#!/bin/bash
# =============================================================================
# ArenaVault Environment Generator
# =============================================================================
# This script detects the machine's IP address and generates a .env file with
# the correct API_URL for the frontend to communicate with the backend.
# It also checks for an available PostgreSQL port.
# =============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Default values
POSTGRES_PORT=5432
API_PORT=5000
FRONTEND_PORT=4200
SERVER_IP=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --ip)
            SERVER_IP="$2"
            shift 2
            ;;
        --postgres-port)
            POSTGRES_PORT="$2"
            shift 2
            ;;
        --api-port)
            API_PORT="$2"
            shift 2
            ;;
        --frontend-port)
            FRONTEND_PORT="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --ip IP              Server IP address (auto-detected if not provided)"
            echo "  --postgres-port PORT PostgreSQL host port (default: 5432)"
            echo "  --api-port PORT      API host port (default: 5000)"
            echo "  --frontend-port PORT Frontend host port (default: 4200)"
            echo "  -h, --help           Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Function to check if port is available
port_available() {
    local port=$1
    if command -v ss &> /dev/null; then
        ! ss -tln | grep -q ":$port "
    elif command -v netstat &> /dev/null; then
        ! netstat -tln 2>/dev/null | grep -q ":$port "
    else
        ! lsof -i :$port &>/dev/null
    fi
}

# Function to get local IP address
get_local_ip() {
    local ip=""
    # Try different methods
    if command -v ip &> /dev/null; then
        ip=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '^127\.' | grep -v '^169\.254\.' | head -1)
    elif command -v ifconfig &> /dev/null; then
        ip=$(ifconfig | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '^127\.' | grep -v '^169\.254\.' | head -1)
    fi

    # Fallback to hostname
    if [ -z "$ip" ]; then
        ip=$(hostname -I 2>/dev/null | awk '{print $1}')
    fi

    # Final fallback
    if [ -z "$ip" ]; then
        ip=$(hostname)
    fi

    echo "$ip"
}

# Header
echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}  ArenaVault Environment Generator${NC}"
echo -e "${CYAN}========================================${NC}"

# Detect or use provided server IP
if [ -z "$SERVER_IP" ]; then
    DETECTED_IP=$(get_local_ip)
    echo -e "\n${YELLOW}Detected IP address: $DETECTED_IP${NC}"
    read -p "Use this IP for API_URL? (Y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        read -p "Enter the server IP or hostname: " SERVER_IP
    else
        SERVER_IP=$DETECTED_IP
    fi
fi

# Check PostgreSQL port availability
echo -e "\n${CYAN}Checking PostgreSQL port availability...${NC}"
POSTGRES_HOST_PORT=$POSTGRES_PORT
for i in $(seq 0 9); do
    TEST_PORT=$((POSTGRES_PORT + i))
    if port_available $TEST_PORT; then
        POSTGRES_HOST_PORT=$TEST_PORT
        echo -e "  ${GREEN}Port $TEST_PORT is available${NC}"
        break
    else
        echo -e "  ${YELLOW}Port $TEST_PORT is in use, trying next...${NC}"
    fi
done

# Construct API URL
API_URL="http://${SERVER_IP}:${API_PORT}/api"

# Generate .env file
echo -e "\n${CYAN}Generating .env file...${NC}"

cat > .env <<EOF
# ArenaVault Environment Configuration
# Auto-generated on $(date '+%Y-%m-%d %H:%M:%S')

# ============================================
# PostgreSQL Configuration
# ============================================
POSTGRES_HOST_PORT=$POSTGRES_HOST_PORT

# ============================================
# Backend API Configuration
# ============================================
API_URL=$API_URL

# ============================================
# Database Connection (for reference)
# ============================================
DATABASE_URL=Host=postgres;Database=arenavaultdb;Username=postgres;Password=ArenaVault2024!

# ============================================
# Frontend Configuration
# ============================================
FRONTEND_HOST_PORT=$FRONTEND_PORT

# ============================================
# Backend Configuration
# ============================================
BACKEND_HOST_PORT=$API_PORT
EOF

echo -e "\n${GREEN}.env file created successfully!${NC}"
echo -e "\n${CYAN}Configuration Summary:${NC}"
echo -e "  ${WHITE}Server IP:       $SERVER_IP${NC}"
echo -e "  ${WHITE}PostgreSQL Port: $POSTGRES_HOST_PORT${NC}"
echo -e "  ${WHITE}API URL:         $API_URL${NC}"
echo -e "  ${WHITE}Frontend Port:   $FRONTEND_PORT${NC}"
echo -e "  ${WHITE}API Port:        $API_PORT${NC}"

echo -e "\n${CYAN}Next steps:${NC}"
echo -e "  ${WHITE}1. Review the .env file if needed${NC}"
echo -e "  ${WHITE}2. Run: docker-compose up --build${NC}"
echo -e "  ${WHITE}3. Access the app at: http://${SERVER_IP}:${FRONTEND_PORT}${NC}"
