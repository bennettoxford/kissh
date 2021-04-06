#!/bin/bash
set -euo pipefail

./install.sh

sleep 1

/srv/kissh/kissh.py --validate

systemctl status kissh.timer

# because datalab-ssh is Type: oneshot, systemctl status will exit with a 3 (not running)
systemctl is-enabled kissh.service
set +e
systemctl status kissh.service
test $? = 3
