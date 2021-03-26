#!/usr/bin/env python3
import pwd
import subprocess
import sys
import traceback
from pathlib import Path

import requests

USERFILE = "https://github.com/ebmdatalab/ssh/blob/main/passwd"
session = requests.Session()


def user_exists(user):
    try:
        user_info = pwd.getpwnam(user)
        return user_info
    except KeyError:
        return None


def create_user(user):
    subprocess.run(
        ["useradd", user, "--create-home", "--shell", "/bin/bash"],
        check=True,
    )
    return pwd.getpwnam(user)


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
    # Note: Github strips key comments :(
    r = session.get(f"https://github.com/{user}.keys")
    r.raise_for_status()

    # Find the correct key by its fingerprint
    for key in r.text.splitlines():
        if get_fingerprint(key) == fingerprint:
            return key


def write_authorized_keys(home, key):
    authorized_keys = Path(home) / ".ssh/authorized_keys"
    authorized_keys.parent.mkdir(exist_ok=True)
    authorized_keys.write_text(key)
    print(f"added keys to {authorized_keys}")


def manage_user(user, fingerprint):
    user_info = user_exists(user)
    key = get_github_key(user, fingerprint)
    if key:
        if not user_info:
            user_info = create_user(user)
        write_authorized_keys(user_info.pw_dir, key)
    else:
        # remove all keys from users authorized_keys
        if user_info:
            write_authorized_keys(user_info.pw_dir, "")
            print(f"Removing all keys for user {user}")
        else:
            print(f"No valid key found for user {user}")


def run(users="passwd"):
    r = session.get(USERFILE)
    r.raise_for_status()
    # TODO: not just rely on Github's https certificate here.
    text = Path("passwd").read_text()

    return_code = 0
    for line in text.splitlines():
        try:
            # split on first ':'
            user, _, fingerprint = line.partition(":")
            manage_user(user, fingerprint)
        except Exception as exc:
            # do not exit, move on to next user
            traceback.print_exc()
            return_code = 1

    return return_code


if __name__ == "__main__":
    sys.exit(run())
