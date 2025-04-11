# Disk-overy

**Disk-overy** is a disk space monitoring and alerting script designed to help you keep track of your system's disk usage and prevent storage-related issues. It monitors mounted partitions and specific directories, sending alerts when usage exceeds predefined thresholds.

## Features
- Monitors disk usage of all mounted partitions.
- Excludes specific partitions (e.g., `tmpfs`, `udev`) from monitoring.
- Tracks specific directories and alerts if their size exceeds thresholds.
- Sends SMS alerts using Twilio when critical thresholds are reached.
- Supports a dry-run mode for testing without sending actual SMS messages.
- Logs historical disk usage for trend analysis.

## How It Works
1. **Partition Monitoring**: The script uses `df -h` to monitor disk usage of all mounted partitions. If a partition exceeds the set limit, it sends an alert.
2. **Directory Monitoring**: Specific directories can be monitored with size thresholds. If a directory exceeds its threshold, an alert is triggered.
3. **Twilio Integration**: SMS alerts are sent using Twilio's API. Credentials and phone numbers are stored in a separate configuration file for security.
4. **Historical Logging**: Disk usage data is logged for future analysis.

## Requirements
- Bash shell
- `curl` (for Twilio API integration)
- Twilio account with valid credentials
- Permissions to access monitored directories

## Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/disk-overy.git
   cd disk-overy
