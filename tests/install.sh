#!/bin/bash
set -euo pipefail

cp -a . /srv/kissh
touch /srv/kissh/.testing
chown -R root:root /srv/kissh

cd /srv/kissh
# ensure remote is http based
git remote set-url origin https://github.com/ebmdatalab/kissh

./install.sh

sleep 1

./kissh validate

systemctl status kissh.timer

systemctl is-enabled kissh.service

# because kissh.service is Type: oneshot, systemctl status will exit with a 3 (not running)
code=0
systemctl status kissh.service || code=$?
test $code = 3

# check a user's .ssh file perms
while IFS= read -r user
do
    # %U = username
    # %G = groupname
    # %a = octal file permissions
    test "$(stat --format '%U:%G:%a' "/home/$user/.ssh")" == "$user:$user:700"
    test "$(stat --format '%U:%G:%a' "/home/$user/.ssh/authorized_keys")" == "$user:$user:600"
done < <(awk -F: '{print $1}' passwd)
