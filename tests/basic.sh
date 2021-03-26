#!/bin/bash
set -euo pipefail

./install.sh

sleep 1

/srv/ssh/ssh.py --validate

systemctl status datalab-ssh.timer

# because datalab-ssh is Type: oneshot, systemctl status will exit with a 3 (not running)
systemctl is-enabled datalab-ssh.service
set +e
systemctl status datalab-ssh.service
test $? = 3
