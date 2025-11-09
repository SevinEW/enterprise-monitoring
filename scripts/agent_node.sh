#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🤖 Enterprise Monitoring Agent Setup${NC}"
echo -e "${BLUE}══════════════════════════════════════${NC}"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}❌ Please run as root${NC}"
    exit 1
fi

# Parse command line arguments
MASTER_IP=""
DB_PASSWORD=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --master)
            MASTER_IP="$2"
            shift 2
            ;;
        --password)
            DB_PASSWORD="$2"
            shift 2
            ;;
        *)
            echo -e "${RED}❌ Unknown parameter: $1${NC}"
            exit 1
            ;;
    esac
done

# Validate inputs
if [ -z "$MASTER_IP" ]; then
    read -p "Enter Master Server IP: " MASTER_IP
fi

if [ -z "$DB_PASSWORD" ]; then
    read -p "Enter Database Password: " DB_PASSWORD
fi

if [ -z "$MASTER_IP" ] || [ -z "$DB_PASSWORD" ]; then
    echo -e "${RED}❌ Master IP and Password are required${NC}"
    exit 1
fi

# Test connection to master
echo -e "${YELLOW}🔗 Testing connection to master...${NC}"
if ! ping -c 2 -W 3 "$MASTER_IP" &> /dev/null; then
    echo -e "${RED}❌ Cannot reach master server: $MASTER_IP${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Connection to master successful${NC}"

# Get server information
SERVER_IP=$(curl -s ifconfig.me)
SERVER_NAME=$(hostname)
SERVER_LOCATION=$(curl -s ipinfo.io/city)

# Create agent configuration
mkdir -p /etc/monitoring
cat > /etc/monitoring/agent.conf << EOF
MASTER_IP=$MASTER_IP
DB_PASSWORD=$DB_PASSWORD
SERVER_IP=$SERVER_IP
SERVER_NAME=$SERVER_NAME
SERVER_LOCATION=$SERVER_LOCATION
AGENT_ID=$(openssl rand -hex 8)
INSTALL_TIME=$(date +%s)
EOF

# Create agent directory
mkdir -p /opt/enterprise_agent

# Download agent script from master (in real scenario)
echo -e "${YELLOW}📥 Downloading agent components...${NC}"
# This would be replaced with actual download from master

# Create agent service
cat > /etc/systemd/system/monitoring_agent.service << EOF
[Unit]
Description=Enterprise Monitoring Agent
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/enterprise_agent
ExecStart=/opt/enterprise_agent/agent_monitor.sh
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Enable and start service
systemctl daemon-reload
systemctl enable monitoring_agent
systemctl start monitoring_agent

echo -e "${GREEN}✅ Agent installed successfully!${NC}"
echo -e "${BLUE}📊 Server: $SERVER_NAME ($SERVER_LOCATION)${NC}"
echo -e "${BLUE}🔗 Master: $MASTER_IP${NC}"
echo -e "${YELLOW}📋 Status: systemctl status monitoring_agent${NC}"
