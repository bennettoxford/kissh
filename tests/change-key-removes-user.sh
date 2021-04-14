#!/bin/bash
set -euo pipefail

tmp=/root/tmp
mkdir -p $tmp
trap 'rm -rf $tmp; kill -- -$$' EXIT

# create an empty userfile
userfile=$tmp/passwd
touch "$userfile"

# create test username and key
username=testuser
authorized_keys=/home/$username/.ssh/authorized_keys
key=$tmp/$username
public=$tmp/$username.pub
ssh-keygen -t ed25519 -C "test" -N "" -f "$key"
test -f "$public"

# serve the file up over http
python3 -m http.server 8080 --directory "$tmp" &

# set kissh to user our test data
export KISSH_USERFILE=$userfile
export KISSH_KEY_URL="http://localhost:8080/{user}.pub"

# empty file, should install no users
./kissh apply
./kissh validate

# no user should exist yet
test ! -f $authorized_keys

# add our user
./kissh update $username "$public"
expected="$username:$(ssh-keygen -lf "$public" | awk '{print $2}')"
test "$expected" = "$(cat "$userfile")"

# create the new user
./kissh apply
./kissh validate

diff "$authorized_keys" "$public"

# remove the user from userfile
echo "$username:SHA256:badfingerprint" > "$userfile"

./kissh apply
./kissh validate

# check the authorized_keys is empty
test "$(cat "$authorized_keys")" = ""
