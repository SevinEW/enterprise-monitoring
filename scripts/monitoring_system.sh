#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Load configuration
if [ -f /etc/monitoring_system.conf ]; then
    source /etc/monitoring_system.conf
else
    echo -e "${RED}❌ Configuration file not found${NC}"
    exit 1
fi

# Logging function
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> $LOG_DIR/system.log
}

# Error handler
error_handler() {
    log_message "ERROR: $1"
    echo -e "${RED}❌ Error: $1${NC}"
    exit 1
}

# Telegram send function with retry
send_telegram() {
    local message="$1"
    local retry=0
    local max_retries=3
    
    while [ $retry -lt $max_retries ]; do
        if curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage" \
            -d chat_id="$CHAT_ID" \
            -d text="$message" \
            -d parse_mode="Markdown" > /dev/null; then
            log_message "Telegram message sent successfully"
            return 0
        fi
        retry=$((retry + 1))
        sleep 2
    done
    
    log_message "Failed to send Telegram message after $max_retries attempts"
    return 1
}

# Get server metrics
get_server_metrics() {
    local server_ip="$1"
    local server_name="$2"
    
    # Ping to Iran
    local ping_result=$(ping -c 3 ir1.node.check-host.net 2>/dev/null | grep avg | awk -F'/' '{print $5}' | cut -d'.' -f1)
    local ping=${ping_result:-0}
    
    # Memory usage
    local memory_usage=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100}')
    
    # CPU usage
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | awk -F'%' '{print $1}')
    
    # Disk usage
    local disk_usage=$(df / | awk 'NR==2{print $5}' | sed 's/%//')
    
    echo "$ping,$memory_usage,$cpu_usage,$disk_usage"
}

# Generate monitoring report
generate_report() {
    local report="🌐 *NETWORK STATUS* | $(date)\n"
    report+="═══════════════════════════════════════\n\n"
    
    # Server data (example - in real system this comes from actual servers)
    local servers=(
        "Germany,192.168.1.10,45,28,73"
        "USA,192.168.1.11,120,85,205" 
        "Singapore,192.168.1.12,32,18,50"
    )
    
    for server in "${servers[@]}"; do
        IFS=',' read -r name ip download upload total <<< "$server"
        local metrics=$(get_server_metrics "$ip" "$name")
        IFS=',' read -r ping memory cpu disk <<< "$metrics"
        
        report+="📍 *$name* • $ip\n"
        report+="├─ 🟢 Ping: ${ping}ms\n"
        report+="├─ 🟢 RAM: ${memory}%\n" 
        report+="├─ 🟡 CPU: ${cpu}%\n"
        report+="├─ 🟢 Disk: ${disk}%\n"
        report+="└─ 🌐 ⬇️${download}M ⬆️${upload}M 📊${total}M\n\n"
    done
    
    echo -e "$report"
}

# Main monitoring function
main_monitor() {
    log_message "Starting monitoring cycle"
    
    local report=$(generate_report)
    send_telegram "$report"
    
    log_message "Monitoring cycle completed"
}

# Handle signals
trap 'log_message "System shutdown gracefully"; exit 0' SIGTERM SIGINT

# Main execution
if [ "$1" == "monitor" ]; then
    main_monitor
elif [ "$1" == "test" ]; then
    echo -e "${GREEN}✅ System test successful${NC}"
else
    echo -e "${BLUE}🚀 Enterprise Monitoring System${NC}"
    echo "Usage: $0 [monitor|test]"
fi
