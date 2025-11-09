#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔄 Enterprise Monitoring System Updater${NC}"
echo -e "${BLUE}════════════════════════════════════════${NC}"

# Check root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}❌ Please run as root${NC}"
    exit 1
fi

# Backup current configuration
echo -e "${YELLOW}📦 Backing up current configuration...${NC}"
if [ -f /etc/monitoring_system.conf ]; then
    cp /etc/monitoring_system.conf /tmp/monitoring_backup.conf
    echo -e "${GREEN}✅ Configuration backed up${NC}"
fi

# Stop services
echo -e "${YELLOW}🛑 Stopping services...${NC}"
systemctl stop monitoring_master 2>/dev/null
systemctl stop monitoring_agent 2>/dev/null

# Remove old files (preserve config and logs)
echo -e "${YELLOW}🧹 Cleaning old files...${NC}"
rm -rf /opt/enterprise_monitor/*.sh
rm -rf /opt/enterprise_monitor/config

# Download latest version
echo -e "${YELLOW}📥 Downloading latest version...${NC}"
TEMP_DIR=$(mktemp -d)
cd $TEMP_DIR

git clone https://github.com/SevinEW/enterprise-monitoring.git 2>/dev/null || {
    echo -e "${RED}❌ Failed to download update${NC}"
    exit 1
}

# Copy new files
echo -e "${YELLOW}📁 Installing new files...${NC}"
cp -r enterprise-monitoring/scripts/* /opt/enterprise_monitor/
cp -r enterprise-monitoring/config/* /opt/enterprise_monitor/config/

# Restore configuration
if [ -f /tmp/monitoring_backup.conf ]; then
    cp /tmp/monitoring_backup.conf /etc/monitoring_system.conf
    echo -e "${GREEN}✅ Configuration restored${NC}"
fi

# Set permissions
chmod +x /opt/enterprise_monitor/*.sh

# Start services
echo -e "${YELLOW}🚀 Starting services...${NC}"
systemctl daemon-reload
systemctl start monitoring_master 2>/dev/null && echo -e "${GREEN}✅ Master service started${NC}"
systemctl start monitoring_agent 2>/dev/null && echo -e "${GREEN}✅ Agent service started${NC}"

# Cleanup
rm -rf $TEMP_DIR

echo -e "${GREEN}✅ System updated successfully!${NC}"
echo -e "${BLUE}🎯 Version: $(date +%Y%m%d)${NC}"
