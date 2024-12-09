#!/bin/bah# Thresholds  

CPU_THRESHOLD=80    # CPU usage percentage  
MEM_THRESHOLD=80    # Memory usage percentage  
DISK_THRESHOLD=90   # Disk usage percentage  
EMAIL="csborle@gmail.com"  
LOG_FILE="/var/log/auth.log"  # Log file location# Function to write logs  
log_message() {  
  local message="$1"  
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" >> "$LOG_FILE"  
}# Function to check CPU usage  
check_cpu_usage() {  
  CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')  
  CPU_USAGE=${CPU_USAGE%.*}  # Convert to integer  
  if (( CPU_USAGE > CPU_THRESHOLD )); then  
    log_message "High CPU usage: $CPU_USAGE%"  
    echo "High CPU usage: $CPU_USAGE%" | mail -s "Alert: CPU Usage Exceeded" "$EMAIL"  
  fi  
}# Function to check memory usage  
check_memory_usage() {  
  MEM_TOTAL=$(free | grep Mem: | awk '{print $2}')  
  MEM_USED=$(free | grep Mem: | awk '{print $3}')  
  MEM_USAGE=$(( MEM_USED * 100 / MEM_TOTAL ))  # Percentage  
  if (( MEM_USAGE > MEM_THRESHOLD )); then  
    log_message "High Memory usage: $MEM_USAGE%"  
    echo "High Memory usage: $MEM_USAGE%" | mail -s "Alert: Memory Usage Exceeded" "$EMAIL"  
  fi  
}# Function to check disk usage  
check_disk_usage() {  
  DISK_USAGE=$(df -h / | grep / | awk '{print $5}' | sed 's/%//')  # Root partition  
  if (( DISK_USAGE > DISK_THRESHOLD )); then  
    log_message "High Disk usage: $DISK_USAGE%"  
    echo "High Disk usage: $DISK_USAGE%" | mail -s "Alert: Disk Usage Exceeded" "$EMAIL"  
  fi  
}# Main monitoring function  
monitor_resources() {  
  log_message "Starting resource monitoring..."  
  check_cpu_usage  
  check_memory_usage  
  check_disk_usage  
  log_message "Resource monitoring completed."  
}# Create log file if it doesn't exist  
if [ ! -f "$LOG_FILE" ]; then  
  touch "$LOG_FILE"  
  chmod 644 "$LOG_FILE"  
fi# Execute the monitoring function  
monitor_resources
