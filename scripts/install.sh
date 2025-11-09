#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Enterprise Monitoring System Setup${NC}"
echo -e "${BLUE}══════════════════════════════════════${NC}"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}❌ Please run as root${NC}"
    exit 1
fi

# Check dependencies
echo -e "${YELLOW}📦 Checking dependencies...${NC}"
for dep in curl wget openssl; do
    if ! command -v $dep &> /dev/null; then
        echo -e "${YELLOW}Installing $dep...${NC}"
        apt-get update && apt-get install -y $dep
    fi
done

# Get Telegram Bot Token
echo -e "${BLUE}🤖 Telegram Bot Setup${NC}"
read -p "Enter Telegram Bot Token: " TELEGRAM_TOKEN
if [ -z "$TELEGRAM_TOKEN" ]; then
    echo -e "${RED}❌ Token is required!${NC}"
    exit 1
fi

# Get Chat ID
read -p "Enter Telegram Chat ID: " CHAT_ID
if [ -z "$CHAT_ID" ]; then
    echo -e "${RED}❌ Chat ID is required!${NC}"
    exit 1
fi

# Get Port
read -p "Enter Port [5-digit] (press Enter for random): " USER_PORT
if [ -z "$USER_PORT" ]; then
    PORT=$(( RANDOM % 90000 + 10000 ))
    echo -e "${YELLOW}🎲 Random port selected: $PORT${NC}"
else
    PORT=$USER_PORT
fi

# Validate port
if ! [[ $PORT =~ ^[0-9]{5}$ ]]; then
    echo -e "${RED}❌ Port must be 5 digits!${NC}"
    exit 1
fi

# Generate DB Password
DB_PASSWORD=$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | head -c 16)
echo -e "${GREEN}🔐 Database Password: $DB_PASSWORD${NC}"

# Create installation directory
mkdir -p /opt/enterprise_monitor
mkdir -p /var/log/monitoring

# Save configuration
cat > /etc/monitoring_system.conf << EOF
TELEGRAM_TOKEN=$TELEGRAM_TOKEN
CHAT_ID=$CHAT_ID
PORT=$PORT
DB_PASSWORD=$DB_PASSWORD
INSTALL_DIR=/opt/enterprise_monitor
LOG_DIR=/var/log/monitoring
EOF

echo -e "${GREEN}✅ Installation completed successfully!${NC}"
echo -e "${BLUE}📁 Install directory: /opt/enterprise_monitor${NC}"
echo -e "${BLUE}🔧 Next: Run agent nodes with the provided password${NC}"
echo -e "${YELLOW}💡 Save this password for agent nodes: $DB_PASSWORD${NC}"
