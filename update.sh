#!/bin/bash
set -euxo pipefail

# skip git update in testing, so we are testing local changes and not
# overwriting them with HEAD.
test -f /srv/kissh/.testing && exit 0

git checkout -f main
git reset --hard origin/main
git pull

# systemd files may have changed in pull, so reload for next time.
systemctl daemon-reload
