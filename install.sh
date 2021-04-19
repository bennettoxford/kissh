#!/bin/bash
set -euo pipefail

# initial run to check it works
echo "Running ssh management to check it works..."
./kissh apply

systemctl enable "$PWD/kissh.service"
systemctl enable "$PWD/kissh.timer"
systemctl start kissh.timer
systemctl start kissh.service

echo "Installed systemd timer to run kissh regularly"
