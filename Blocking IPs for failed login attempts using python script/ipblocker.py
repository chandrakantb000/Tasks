import re
import subprocess
from collections import Counter
import os

# Path to the WordPress log file
LOG_FILE = "/var/log/auth.log"  # Update this path if needed

# Define the threshold for failed login attempts
FAILURE_THRESHOLD = 5

# Regular expression to match failed login attempts in WordPress logs
FAILED_LOGIN_PATTERN = r"Authentication attempt for unknown user .* from (\d+\.\d+\.\d+\.\d+)"

def parse_logs(file_path):
    """
    Parse the log file and extract IP addresses causing failed login attempts.
    """
    failed_ips = []
    try:
        with open(file_path, 'r') as log_file:
            for line in log_file:
                match = re.search(FAILED_LOGIN_PATTERN, line)
                if match:
                    failed_ips.append(match.group(1))
    except FileNotFoundError:
        print(f"Log file not found: {file_path}")
    except PermissionError:
        print(f"Permission denied: Unable to read {file_path}")
    return failed_ips

def update_firewall(blocked_ips):
    """
    Add firewall rules to block IP addresses using iptables.
    """
    for ip in blocked_ips:
        try:
            # Check if the IP is already blocked
            result = subprocess.run(
                ["iptables", "-L", "-n"],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True
            )
            if ip in result.stdout:
                print(f"IP {ip} is already blocked.")
                continue

            # Add a rule to block the IP
            print(f"Blocking IP: {ip}")
            subprocess.run(
                ["iptables", "-A", "INPUT", "-s", ip, "-j", "DROP"],
                check=True
            )
        except subprocess.CalledProcessError as e:
            print(f"Error updating firewall for IP {ip}: {e}")

def main():
    # Ensure the script is run as root
    if os.geteuid() != 0:
        print("This script must be run as root.")
        return

    # Parse logs to get IPs with failed login attempts
    failed_ips = parse_logs(LOG_FILE)
    if not failed_ips:
        print("No failed login attempts found.")
        return

    # Count the occurrences of each IP
    ip_counts = Counter(failed_ips)
    print("Failed login attempts per IP:")
    for ip, count in ip_counts.items():
        print(f"{ip}: {count} attempts")

    # Identify IPs exceeding the threshold
    blocked_ips = [ip for ip, count in ip_counts.items() if count > FAILURE_THRESHOLD]
    if not blocked_ips:
        print("No IPs exceed the failure threshold.")
        return

    # Block IPs
    update_firewall(blocked_ips)

if __name__ == "__main__":
    main()

