#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${RED}🗑️ Enterprise Monitoring System Uninstaller${NC}"
echo -e "${RED}═══════════════════════════════════════════${NC}"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}❌ Please run as root${NC}"
    exit 1
fi

# Confirmation
echo -e "${YELLOW}⚠️  This will completely remove the monitoring system${NC}"
read -p "Are you sure? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}❌ Uninstall cancelled${NC}"
    exit 1
fi

echo -e "${YELLOW}🛑 Stopping services...${NC}"

# Stop services
systemctl stop monitoring_master 2>/dev/null
systemctl stop monitoring_agent 2>/dev/null
systemctl disable monitoring_master 2>/dev/null
systemctl disable monitoring_agent 2>/dev/null

# Remove systemd services
echo -e "${YELLOW}📋 Removing system services...${NC}"
rm -f /etc/systemd/system/monitoring_master.service
rm -f /etc/systemd/system/monitoring_agent.service

# Remove installation files
echo -e "${YELLOW}📁 Removing files...${NC}"
rm -rf /opt/enterprise_monitor
rm -f /etc/monitoring_system.conf

# Remove log files
echo -e "${YELLOW}📊 Cleaning logs...${NC}"
rm -rf /var/log/monitoring

# Remove cron jobs
echo -e "${YELLOW}⏰ Removing scheduled tasks...${NC}"
crontab -l | grep -v 'monitoring' | crontab -

# Reload systemd
systemctl daemon-reload

echo -e "${GREEN}✅ Enterprise Monitoring System completely removed!${NC}"
echo -e "${BLUE}🎯 All files, logs, and configurations have been deleted${NC}"
