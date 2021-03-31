#!/usr/bin/env python3
import sys
from pathlib import Path

import ssh


def run(user, keyfile, userfile=Path("passwd")):
    fingerprint = ssh.get_fingerprint(Path(keyfile).read_text())

    if ssh.get_github_key(user, fingerprint) is None:
        print(f"{keyfile} is not registerd for Github user {user}")
        return 1

    users = dict(ssh.get_users(userfile))
    # update user's fingerprint
    users[user] = fingerprint
    content = "\n".join(f"{u}:{f}" for u, f in users.items())
    ssh.write_file(userfile, content)


if __name__ == "__main__":
    args = sys.argv[1:]
    if len(args) != 2 or "--help" in args or "-h" in args:
        sys.exit(f"usage: {sys.argv[0]} GITHUB_USER PATH_TO_PUBLIC_KEY")

    sys.exit(run(*args))
