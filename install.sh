#!/bin/bash
set -euo pipefail

# initial run to check it works
echo "Running ssh management to check it works..."
./kissh apply

systemctl enable "$PWD/kissh.service"
systemctl enable "$PWD/kissh.timer"
systemctl start kissh.timer
git branch
systemctl start kissh.service || { journalctl -u kissh.service; exit 1; }

echo "Installed systemd timer to run kissh regularly"
