# WatchTower  

## Overview  
**WatchTower** is a comprehensive **System Resource Monitor Script** designed to monitor critical system metrics such as CPU, Memory, Disk, and Network usage. It provides real-time warnings and critical alerts based on configurable thresholds, ensuring proactive system management.  

## Features  
- Monitors:  
  - **CPU Usage**: Displays usage and highlights processes consuming the most resources.  
  - **Memory Usage**: Tracks memory utilization and identifies top memory-consuming processes.  
  - **Disk Usage**: Checks disk usage for all mounted partitions.  
  - **Network Usage**: Displays incoming and outgoing traffic for active network interfaces.  
  - **System Uptime**: Recommends rebooting if uptime exceeds a configurable threshold.  
- Color-coded alerts:  
  - **Green**: Normal usage.  
  - **Yellow**: Warning (usage near threshold).  
  - **Red**: Critical (usage exceeds threshold).  
- Summary report at the end of the script.  
- Automatically installs required dependencies if missing.  

## Requirements   
- Linux-based operating system.  
- Dependencies:  
  - `bc`: For floating-point arithmetic.  
  - `awk`: For text processing.  
  - `iostat`: For detailed CPU and I/O statistics (part of `sysstat` package).  

## Installation  
1. Clone the repository:  
   ```bash  
   git clone https://github.com/yourusername/watchtower.git  
   cd watchtower  

2. Make the script executable  
   chmod +x watchtower.sh  

## Usage  
Run the script:  
./watchtower.sh  

## Configuration  
You can customize thresholds by modifying the following variables in the script:  

CPU Limit: CPU_LIMIT=80  
Memory Limit: MEM_LIMIT=80  
Disk Limit: DISK_LIMIT=80  

## License  
This project is licensed under the MIT License. See the LICENSE file for details.  

## Author  
bidfax  
Feel free to reach out for questions or suggestions!  

