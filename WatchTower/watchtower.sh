#############################################################################################
## Script Name: WatchTower                                                                 ##
## Description: System Resource Monitor Script                                             ##
## This script monitors CPU, Memory, Disk, and Network usage.                              ##
## It provides warnings and critical alerts based on usage thresholds.                     ##
## It also checks for the installation of required commands and installs them if missing.  ##
## Made by: bidfax                                                                         ##
#############################################################################################


#!/bin/bash
# Function to check if a service/command is installed and install it if missing
check_and_install() {
    local service=$1
    local install_command=$2

    if ! command -v "$service" &> /dev/null; then
        echo "Service '$service' is not installed. Installing..."
        eval "$install_command"
        if [ $? -ne 0 ]; then
            echo "Error: Failed to install $service. Please install it manually." >&2
            exit 1
        fi
    else
        echo "Service '$service' is already installed."
    fi
}

# Initialize counters for warnings and critical warnings
critical_count=0
warning_count=0

# Function to increment counters based on usage
increment_counters() {
    local usage=$1
    local limit=$2
    if (( $(echo "$usage > $limit" | bc -l) )); then
        ((critical_count++))
    elif (( $(echo "$usage > $limit - 10" | bc -l) )); then
        ((warning_count++))
    fi
}

# Define colors
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

CPU_LIMIT=80
MEM_LIMIT=80
DISK_LIMIT=80
# Check if bc is installed, if not install it
check_and_install "bc" "sudo yum install -y bc"
check_and_install "iostat" "sudo yum install -y sysstat"

# System Resource Monitor Script
echo "System Resource Usage:"
echo "-----------------------"

# Display CPU usage
echo "CPU Usage:"
cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')
increment_counters "$cpu_usage" "$CPU_LIMIT"
if (( $(echo "$cpu_usage > $CPU_LIMIT" | bc -l) )); then
    echo -e "${RED}  Usage: $cpu_usage% !!!CRITICAL!!!${NC}"
elif (( $(echo "$cpu_usage > $((CPU_LIMIT - 10))" | bc -l) )); then
    echo -e "${YELLOW}  Usage: $cpu_usage% !!!WARNING!!!${NC}"
else
    echo -e "${GREEN}  Usage: $cpu_usage%${NC}"
fi

# Display Memory usage
echo "Memory Usage:"
mem_usage=$(free | awk '/^Mem:/ {printf "%.0f", $3/$2 * 100}')
increment_counters "$mem_usage" "$MEM_LIMIT"
if (( mem_usage > MEM_LIMIT )); then
    echo -e "${RED}  Used: $mem_usage% !!!CRITICAL!!!${NC}"
elif (( mem_usage > MEM_LIMIT - 10 )); then
    echo -e "${YELLOW}  Used: $mem_usage% !!!WARNING!!!${NC}"
else
    echo -e "${GREEN}  Used: $mem_usage%${NC}"
fi

# Display Disk usage
echo "Disk Usage:"
df -h | awk 'NR>1 {print $0}' | while read -r line; do
    # Extract the usage percentage and the partition name
    usage=$(echo "$line" | awk '{print $5}' | sed 's/%//')
    partition=$(echo "$line" | awk '{print $6}')

    # Skip lines without valid usage or partition data
    if [[ -z "$usage" || -z "$partition" ]]; then
        continue
    fi
    increment_counters "$usage" "$DISK_LIMIT"
    # Check if the usage exceeds the limit
    if (( usage > DISK_LIMIT )); then
        echo -e "${RED}  Partition: $partition - Usage: $usage% !!!CRITICAL!!!${NC}"
    elif (( usage > DISK_LIMIT - 10 )); then
        echo -e "${YELLOW}  Partition: $partition - Usage: $usage% !!!WARNING!!!${NC}"
    else
        echo -e "${GREEN}  Partition: $partition - Usage: $usage%${NC}"
    fi
done

# Display Swap usage
echo "Swap Usage:"
swap_usage=$(free | awk '/^Swap:/ {printf "%.0f", $3/$2 * 100}')
increment_counters "$swap_usage" "$MEM_LIMIT"
if (( $(echo "$swap_usage > $MEM_LIMIT" | bc -l) )); then
    echo -e "${RED}  Used: $swap_usage% !!!CRITICAL!!!${NC}"
elif (( $(echo "$swap_usage > $MEM_LIMIT - 10" | bc -l) )); then
    echo -e "${YELLOW}  Used: $swap_usage% !!!WARNING!!!${NC}"
else
    echo -e "${GREEN}  Used: $swap_usage%${NC}"
fi

echo -e ""
echo "-----------------------"
echo -e ""

# Display Network usage
echo "Network Usage:"
echo "  Incoming:"
cat /proc/net/dev | awk '/eth0|wlan0/ {print "    " $1 " - Received: " $2 " bytes"}'
echo "  Outgoing:"
cat /proc/net/dev | awk '/eth0|wlan0/ {print "    " $1 " - Transmitted: " $10 " bytes"}'

echo -e ""
echo "-----------------------"
echo -e ""

# Display System Uptime
echo "System Uptime:"
uptime -p

# # Check if uptime exceeds 10 days
uptime_days=$(uptime -p | grep -oP '\d+(?= days)' || echo 0) # Extract days or default to 0
if (( uptime_days > 10 )); then
    echo -e "${YELLOW}Reboot recommended: System has been running for over 10 days (${uptime_days} days).${NC}"
fi

# # Check if uptime exceeds 10 minutes (for testing purposes)
# uptime_minutes=$(awk '{print int($1 / 60)}' /proc/uptime) # Extract uptime in minutes
# if (( uptime_minutes > 61 )); then
#     echo -e "${YELLOW}Reboot recommended: System has been running for over 10 minutes (${uptime_minutes} minutes).${NC}"
# fi

echo -e ""
echo "-----------------------"
echo -e ""

# Display Top 5 CPU-consuming processes
echo "Top 5 CPU-consuming processes:"
echo -e "PID\tCOMMAND\t\t%CPU"
ps -eo pid,comm,%cpu --sort=-%cpu | head -n 6 | while read -r pid comm cpu; do
    if [[ "$pid" == "PID" ]]; then
        continue # Skip the header row
    fi
    if (( $(echo "$cpu > 80" | bc -l) )); then
        echo -e "${RED}$pid\t$comm\t\t$cpu% !!!CRITICAL!!!${NC}"
    elif (( $(echo "$cpu > 70" | bc -l) )); then
        echo -e "${YELLOW}$pid\t$comm\t\t$cpu% !!!WARNING!!!${NC}"
    else
        echo -e "${GREEN}$pid\t$comm\t\t$cpu%${NC}"
    fi
done

echo -e ""

# Display Top 5 Memory-consuming processes
echo "Top 5 Memory-consuming processes:"
echo -e "PID\tCOMMAND\t\t%MEM"
ps -eo pid,comm,%mem --sort=-%mem | head -n 6 | while read -r pid comm mem; do
    if [[ "$pid" == "PID" ]]; then
        continue # Skip the header row
    fi
    if (( $(echo "$mem > 80" | bc -l) )); then
        echo -e "${RED}$pid\t$comm\t\t$mem% !!!CRITICAL!!!${NC}"
    elif (( $(echo "$mem > 80" | bc -l) )); then
        echo -e "${YELLOW}$pid\t$comm\t\t$mem% !!!WARNING!!!${NC}"
    else
        echo -e "${GREEN}$pid\t$comm\t\t$mem%${NC}"
    fi
done

echo -e ""
echo "-----------------------"
echo -e ""


# Display Disk I/O
echo "Disk I/O:"
iostat -dx 1 1 | awk 'NR>3 {printf "  Device: %-10s Read/s: %-10s Write/s: %-10s Read KB/s: %-10s Write KB/s: %-10s\n", $1, $2, $3, $4, $5}'
echo -e ""

echo "-----------------------"
echo "Monitoring complete."

# Add a summary report at the end
echo -e ""
echo "Summary Report:"
echo "Critical Warnings: $critical_count"
echo "Warnings: $warning_count"
