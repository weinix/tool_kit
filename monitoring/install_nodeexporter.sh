#!/bin/bash

arch="${ARCH:-linux-amd64}"
bin_dir="${BIN_DIR:-/usr/local/bin}"

latest_version=$(curl --silent "https://api.github.com/repos/prometheus/node_exporter/releases/latest" | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')
wget "https://github.com/prometheus/node_exporter/releases/download/v$latest_version/node_exporter-$latest_version.$arch.tar.gz" \
    -O /tmp/node_exporter.tar.gz

mkdir -p /tmp/node_exporter

cd /tmp || { echo "ERROR! No /tmp found.."; exit 1; }

tar xfz /tmp/node_exporter.tar.gz -C /tmp/node_exporter || { echo "ERROR! Extracting the node_exporter tar"; exit 1; }
cp "/tmp/node_exporter/node_exporter-$latest_version.$arch/node_exporter" "$bin_dir"
chown root:staff "$bin_dir/node_exporter"


if [ -x "$(command -v systemctl)" ]; then
    cat << EOF > /lib/systemd/system/node-exporter.service
[Unit]
Description=Prometheus agent
After=network.target
StartLimitIntervalSec=0

[Service]
Type=simple
Restart=always
RestartSec=1
ExecStart=$bin_dir/node_exporter

[Install]
WantedBy=multi-user.target
EOF

    systemctl enable node-exporter
    systemctl start node-exporter
elif [ -x "$(command -v chckconfig)" ]; then
    cat << EOF >> /etc/inittab
::respawn:/opt/node_exporter/node_exporter
EOF
elif [ -x "$(command -v initctl)" ]; then
    cat << EOF > /etc/init/node-exporter.conf
start on runlevel [23456]
stop on runlevel [016]
exec /opt/node_exporter/node_exporter
respawn
EOF

    initctl reload-configuration
    stop node-exporter || true && start node-exporter
else
    echo "No known service management found" >&2;
    exit 1;
fi


echo "Node exporter insalled."
