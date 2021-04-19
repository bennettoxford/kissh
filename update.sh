#!/bin/bash
set -euxo pipefail
git checkout -f main
git reset --hard origin/main
git pull

# systemd files may have changed in pull, so reload for next time.
systemctl daemon-reload
