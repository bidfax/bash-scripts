#############################################################################################
## Script Name: Disk-overy                                                                 ##
## Description:                                                                            ##
## This script monitors disk usage and sends alerts via SMS using Twilio.                  ##
## It checks the disk usage of all mounted partitions and specific directories.            ##
## It sends critical and warning alerts based on usage thresholds.                         ##
## It also logs historical disk usage data for trend analysis.                             ##
## It requires Twilio credentials for sending SMS alerts.                                  ##
## It excludes certain partitions from monitoring.                                         ##
## It can be run in dry-run mode for testing purposes.                                     ##
## It uses the Twilio API to send SMS messages.                                            ##
## It requires the Twilio account SID, auth token, and phone numbers to be set up.         ##
## Made by: bidfax                                                                         ##
#############################################################################################


#!/bin/bash
# DRY RUN to test if twilio would send SMS message
DRY_RUN=true  # Set to true for testing

# Historical disk usage data to compare and detect trends
HISTORICAL_LOG="/path/to/script/disk_usage_history.log"

# Check if twilio config is on it's place   
if [ ! -f /path/to/script/.twilio-config.sh ]; then
    echo "Error: Twilio configuration file not found!" >&2
    exit 1
fi

# Configuration file for twilio
source /path/to/script/.twilio-config.sh

# Health check for Twilio
check_twilio() {
    response=$(curl -s -o /dev/null -w "%{http_code}" -u "$TWILIO_ACCOUNT_SID:$TWILIO_AUTH_TOKEN" \
        "https://api.twilio.com/2010-04-01/Accounts/$TWILIO_ACCOUNT_SID.json")
    if [ "$response" -ne 200 ]; then
        echo "Error: Twilio credentials are invalid!" >&2
        exit 1
    fi
}

# Call the health check at the start
check_twilio

# Set the disk usage limit (in percentage)
LIMIT=47

# Function to send SMS using Twilio
send_sms() {
    local message=$1
    curl -s -X POST "https://api.twilio.com/2010-04-01/Accounts/$TWILIO_ACCOUNT_SID/Messages.json" \
        --data-urlencode "Body=$message" \
        --data-urlencode "From=$TWILIO_PHONE_NUMBER" \
        --data-urlencode "To=$ALERT_PHONE_NUMBER" \
        -u "$TWILIO_ACCOUNT_SID:$TWILIO_AUTH_TOKEN" > /dev/null 2>&1
}

# Get the disk usage of all mounted partitions
df -h | awk 'NR==1 || NR>1 {print $0}' | while read line; do
    if [[ $line == Filesystem* ]]; then
        # Print the header as is
        echo "$line"
        continue
    fi

# Excluding partitions | FEATURE
EXCLUDE_PARTITIONS="tmpfs|udev"

if echo "$line" | grep -Eq "$EXCLUDE_PARTITIONS"; then
    continue
fi

# Extract the usage percentage and the partition name
usage=$(echo $line | awk '{print $5}' | sed 's/%//')

# Execute write to historical log
echo "$(date '+%Y-%m-%d %H:%M:%S') $line" >> "$HISTORICAL_LOG"

# Check if the usage exceeds the limit
    if [ "$usage" -gt "$LIMIT" ]; then
        echo -e "\033[31m$line !!!CRITICAL!!!\033[0m"

        if [ "$DRY_RUN" = true ]; then
            echo "Dry-run mode: Would send SMS: ALERT: Partition $(echo $line | awk '{print $6}') is above the limit! Usage: $usage%"
        else
            send_sms "ALERT: Partition $(echo $line | awk '{print $6}') is above the limit! Usage: $usage%"
        fi

    elif [ "$usage" -gt $((LIMIT - 10)) ]; then
    echo -e "\033[33m$line !!!WARNING!!!\033[0m"

        if [ "$DRY_RUN" = true ]; then
            echo "Dry-run mode: Would send SMS: WARNING: Partition $(echo $line | awk '{print $6}') is near the limit! Usage: $usage%"
        else
            send_sms "WARNING: Partition $(echo $line | awk '{print $6}') is near the limit! Usage: $usage%"
        fi
    else
        echo "$line"
    fi
done

# Define directories to monitor and their thresholds
MONITORED_DIRECTORIES=(
    "/dev:1G"
)

# Function to convert human-readable sizes to bytes
convert_to_bytes() {
    local size=$1
    echo $size | awk '/G$/ {print $1 * 1024 * 1024 * 1024} /M$/ {print $1 * 1024 * 1024} /K$/ {print $1 * 1024} /^[0-9]+$/ {print $1}'
}

# Monitor each directory
for entry in "${MONITORED_DIRECTORIES[@]}"; do
    dir=$(echo $entry | cut -d':' -f1)
    threshold=$(echo $entry | cut -d':' -f2)
    threshold_bytes=$(convert_to_bytes $threshold)

    # Get the current size of the directory in bytes
    current_size=$(du -sb "$dir" 2>/dev/null | awk '{print $1}')

    # Check if the directory exceeds the threshold
    if [ "$current_size" -gt "$threshold_bytes" ]; then
        echo -e "\033[31mDirectory $dir exceeds threshold ($threshold) !!!CRITICAL!!!\033[0m"

        if [ "$DRY_RUN" = true ]; then
            echo "Dry-run mode: Would send SMS: ALERT: Directory $dir exceeds threshold ($threshold). Current size: $(du -sh "$dir" | awk '{print $1}')"
        else
            send_sms "ALERT: Directory $dir exceeds threshold ($threshold). Current size: $(du -sh "$dir" | awk '{print $1}')"
        fi
    fi
done