#!/usr/bin/env python3
import os
import sys
import tempfile
from pathlib import Path

import ssh


def run(user, keyfile, userfile=Path("passwd")):
    fingerprint = ssh.get_fingerprint(Path(keyfile).read_text())

    if ssh.get_github_key(user, fingerprint) is None:
        print(f"{keyfile} is not registerd for Github user {user}")
        return 1

    users = userfile.read_text()
    tmp = Path(".tmp_passwd")

    written = False
    new_line = f"{user}:{fingerprint}\n"
    try:
        with tmp.open("w") as f:
            for line in users.splitlines():
                if line.startswith(user + ":"):
                    f.write(new_line)
                    written = True
                else:
                    f.write(line + "\n")

            if not written:
                f.write(new_line)

        tmp.rename(userfile)
    finally:
        if tmp.exists():
            tmp.unlink()


if __name__ == "__main__":
    args = sys.argv[1:]
    if len(args) != 2 or "--help" in args or "-h" in args:
        sys.exit(f"usage: {sys.argv[0]} GITHUB_USER PATH_TO_PUBLIC_KEY")

    sys.exit(run(*args))
