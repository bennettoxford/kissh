#!/bin/bash
set -euo pipefail

cp -a . /srv/kissh
cd /srv/kissh
# ensure remote is http based
git remote set-url origin https://github.com/ebmdatalab/kissh

./install.sh

sleep 1

./kissh validate

systemctl status kissh.timer

# because kissh.service is Type: oneshot, systemctl status will exit with a 3 (not running)
systemctl is-enabled kissh.service
set +e
systemctl status kissh.service
test $? = 3
