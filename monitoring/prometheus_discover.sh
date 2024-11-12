#!/bin/bash

# Define the subnet and port to scan
SUBNET="192.168.1.0/24"
PORT="9100"

# Output file for the Prometheus configuration
OUTPUT_FILE="/tmp/prometheus.yml"
FINAL_CONFIG="/etc/prometheus/prometheus.yml"

# Function to perform a reverse DNS lookup and trim domain part
get_hostname() {
    local ip=$1
    nslookup "$ip" | awk -F'= ' '/name =/ {print $2}'
}

# Start building the Prometheus configuration file
cat <<EOL > "$OUTPUT_FILE"
# Prometheus configuration generated by script

global:
  scrape_interval: 15s
  evaluation_interval: 15s

alerting:
  alertmanagers:
    - static_configs:
        - targets:
          # - alertmanager:9093

rule_files:
  # - "first_rules.yml"
  # - "second_rules.yml"

scrape_configs:
  - job_name: "pve-exporter"
    metrics_path: /pve
    params:
      module: [default]
    static_configs:
      - targets:
        - proxmox:9221

  - job_name: "prometheus"
    static_configs:
      - targets:
        - localhost:9090
EOL

# Scan the network for open port 9100
set -x
for ip in $(nmap -p "$PORT" --open -oG - "$SUBNET" | awk '/Up$/{print $2}'); do
    hostname=$(get_hostname "$ip")
    
    # If hostname is empty, skip this IP
    if [[ -z "$hostname" ]]; then
        continue
    fi

    # Append to Prometheus configuration
    echo "        - ${hostname}:9100" >> "$OUTPUT_FILE"
done

echo "Prometheus scrape configuration generated at $OUTPUT_FILE"

cp $OUTPUT_FILE $FINAL_CONFIG
systemctl restart prometheus
