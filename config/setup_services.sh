#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}🔧 Setting up system services...${NC}"

# Check root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}❌ Please run as root${NC}"
    exit 1
fi

# Copy service files
cp monitoring_master.service /etc/systemd/system/
cp monitoring_agent.service /etc/systemd/system/

# Set permissions
chmod 644 /etc/systemd/system/monitoring_*.service

# Reload systemd
systemctl daemon-reload

# Enable services based on role
if [ -f /etc/monitoring_system.conf ]; then
    echo -e "${YELLOW}🔄 Enabling master service...${NC}"
    systemctl enable monitoring_master
fi

if [ -f /etc/monitoring/agent.conf ]; then
    echo -e "${YELLOW}🔄 Enabling agent service...${NC}"
    systemctl enable monitoring_agent
fi

echo -e "${GREEN}✅ Services setup completed!${NC}"
echo -e "${YELLOW}📋 Usage: systemctl [start|stop|status] monitoring_master${NC}"
