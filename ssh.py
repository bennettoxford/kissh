#!/usr/bin/env python3
import argparse
import pwd
import subprocess
import sys
import traceback
from pathlib import Path

import requests

USERFILE = "https://raw.githubusercontent.com/ebmdatalab/ssh/main/passwd"
session = requests.Session()


def user_exists(user):
    try:
        user_info = pwd.getpwnam(user)
        return Path(user_info.pw_dir) / ".ssh/authorized_keys"
    except KeyError:
        return None


def create_user(user):
    subprocess.run(
        ["useradd", user, "--create-home", "--shell", "/bin/bash"],
        check=True,
    )
    return user_exists(user)


def get_fingerprint(key):
    ps = subprocess.run(
        ["ssh-keygen", "-lf-"],
        input=key,
        check=True,
        capture_output=True,
        text=True,
    )
    # ssh-keygen output format is: "SIZE HASH:VALUE no comment (TYPE)".
    # eg: "256 SHA256:AsFa6mIf22oiMZSW7yNn3Fip2Ri6DAzjrh+KiZ+axWg no comment (ED25519)"
    return ps.stdout.split()[1]


def get_github_key(user, fingerprint):
    """Get Github user's key that matches fingerprint."""
    # Do not use the api to avoid ratelimiting
    r = session.get(f"https://github.com/{user}.keys")
    r.raise_for_status()

    # Find the correct key by its fingerprint
    for key in r.text.splitlines():
        if get_fingerprint(key) == fingerprint:
            return key


def write_file(path, contents):
    path.parent.mkdir(exist_ok=True)
    path.write_text(contents)


def manage_user(user, fingerprint):
    auth_keys = user_exists(user)
    key = get_github_key(user, fingerprint)
    if key:
        if not auth_keys:
            auth_keys = create_user(user)
        write_file(auth_keys, key)
    else:
        # remove all keys from users authorized_keys
        if user_info:
            write_file(auth_keys, "")
            print(f"Removing all keys for user {user}")
        else:
            print(f"No valid key found for user {user}")


def validate_user(user, fingerprint):
    auth_keys = user_exists(user)
    key = get_github_key(user, fingerprint)

    if auth_keys:
        if key:
            if get_fingerprint(auth_keys.read_text()) == fingerprint:
                print(f"User {user} has valid authorized_keys")
                return True
            else:
                print(f"User {user} has invalid authorized_keys!")
        else:
            print(f"User {user} exists but is not expected")
    else:
        print(f"User {user} is expected but does not exist on system")

    return False


def get_users(path):
    user_lines = path.read_text().splitlines()
    for i, line in enumerate(user_lines):
        if not line or line[0] == "#":
            continue

        # split on first ':'
        user, _, fingerprint = line.partition(":")

        if not fingerprint:
            print(f"Invalid line '{line}' in users file")
        else:
            yield user, fingerprint


def run(args):
    userfile = Path(args.users)
    return_code = 0
    for user, fingerprint in get_users(userfile):
        try:
            if args.validate:
                valid = validate_user(user, fingerprint)
                if not valid:
                    return_code = 1
            else:
                manage_user(user, fingerprint)
        except Exception as exc:
            # do not exit, move on to next user
            traceback.print_exc()
            return_code = 1

    return return_code


parser = argparse.ArgumentParser("ssh management")
parser.add_argument("users", nargs="?", default="passwd", help="users file to use")
parser.add_argument(
    "--validate",
    action="store_true",
    help="Do not create users, but validate against input",
)


if __name__ == "__main__":
    args = parser.parse_args()
    sys.exit(run(args))
