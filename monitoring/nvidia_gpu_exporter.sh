#!/bin/bash

arch="${ARCH:-linux-amd64}"
bin_dir="${BIN_DIR:-/usr/local/bin}"

# Fetch the latest version number from the GitHub API
latest_version=$(curl --silent "https://api.github.com/repos/utkuozdemir/nvidia_gpu_exporter/releases/latest" | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')

# Download the latest version of nvidia_gpu_exporter
wget "https://github.com/utkuozdemir/nvidia_gpu_exporter/releases/download/v$latest_version/nvidia_gpu_exporter_${latest_version}_$arch.deb" \
    -O /tmp/nvidia_gpu_exporter.deb


tar xfz /tmp/nvidia_gpu_exporter.tar.gz -C /tmp/nvidia_gpu_exporter || { echo "ERROR! Extracting the nvidia_gpu_exporter tar"; exit 1; }
apt install /tmp/nvidia_gpu_exporter.deb -y

#cat <<EOF > /etc/systemd/system/nvidia_gpu_exporter.service
#[Unit]
#Description=NVIDIA GPU exporter
#After=local-fs.target network-online.target network.target
#Wants=local-fs.target network-online.target network.target
#
#[Service]
#Type=simple
#ExecStart=$bin_dir/nvidia_gpu_exporter
#
#[Install]
#WantedBy=multi-user.target
#EOF
#
#systemctl enable nvidia_gpu_exporter.service
#systemctl start nvidia_gpu_exporter.service

echo "SUCCESS! Installation succeeded!"
