#!/bin/bash
set -euo pipefail

target=${1:-/srv/kissh}
parent=$(dirname "$target")

mkdir -p "$parent"
cp -a . "$target"

# initial run to check it works
echo "Running ssh management to check it works..."
"$target/kissh.py"

# ensure the service and timer are set up
systemctl enable "$target/kissh.timer"
systemctl enable "$target/kissh.service"
systemctl stop kissh.service
systemctl stop kissh.timer
systemctl daemon-reload
systemctl start kissh.service
systemctl start kissh.timer

echo "Installed systemd timer to run kissh regularly"
