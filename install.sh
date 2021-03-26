#!/bin/bash
set -euo pipefail

target=${1:-/srv/ssh}
parent=$(dirname "$target")

mkdir -p "$parent"
cp -a . "$target"

# initial run to check it works
echo "Running ssh management to check it works..."
"$target/ssh.py"

# ensure the service and timer are set up
systemctl enable $target/datalab-ssh.timer
systemctl enable $target/datalab-ssh.service
systemctl stop datalab-ssh.service
systemctl stop datalab-ssh.timer
systemctl daemon-reload
systemctl start datalab-ssh.service
systemctl start datalab-ssh.timer

echo "Installed systemd timer to run regularly"
