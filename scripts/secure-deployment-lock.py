#!/usr/bin/env python3
"""Secure, test-only deployment lock bootstrap. Python 3.6 compatible."""

import fcntl
import os
import re
import stat
import sys


def main():
    if len(sys.argv) < 3:
        raise RuntimeError(
            "Usage: secure-deployment-lock.py ROOT COMMAND [ARGS...]"
        )

    if os.environ.get("VOIPCENTRA_TEST_MODE") != "1":
        raise RuntimeError("Development lock bootstrap is test-only")

    root = sys.argv[1]
    command = sys.argv[2:]

    if not re.fullmatch(
        r"/tmp/voipcentra-dual-[A-Za-z0-9._-]+", root
    ):
        raise RuntimeError("Invalid isolated deployment root")

    if ".." in os.path.basename(root):
        raise RuntimeError("Invalid test root name")

    dir_flags = (
        os.O_RDONLY |
        os.O_DIRECTORY |
        os.O_NOFOLLOW |
        os.O_CLOEXEC
    )

    root_fd = os.open(root, dir_flags)

    try:
        info = os.fstat(root_fd)

        if not stat.S_ISDIR(info.st_mode):
            raise RuntimeError("Deployment root is not a directory")

        if info.st_uid != os.geteuid():
            raise RuntimeError("Deployment root ownership mismatch")

        if stat.S_IMODE(info.st_mode) & 0o022:
            raise RuntimeError("Deployment root is writable by others")

        flags = (
            os.O_CREAT |
            os.O_RDWR |
            os.O_NOFOLLOW |
            os.O_CLOEXEC
        )

        fd = os.open(
            ".voipcentra-deploy.lock",
            flags,
            0o600,
            dir_fd=root_fd
        )

        try:
            lock_info = os.fstat(fd)

            if not stat.S_ISREG(lock_info.st_mode):
                raise RuntimeError("Invalid deployment lock type")

            if lock_info.st_uid != os.geteuid():
                raise RuntimeError("Deployment lock ownership mismatch")

            if lock_info.st_nlink != 1:
                raise RuntimeError("Deployment lock hardlink rejected")

            if stat.S_IMODE(lock_info.st_mode) & 0o077:
                raise RuntimeError("Deployment lock permissions too broad")

            try:
                fcntl.flock(
                    fd,
                    fcntl.LOCK_EX | fcntl.LOCK_NB
                )
            except (OSError, IOError):
                raise RuntimeError("Deployment lock unavailable")

            os.dup2(fd, 9, inheritable=True)
            os.set_inheritable(9, True)

        finally:
            if fd != 9:
                os.close(fd)

    finally:
        os.close(root_fd)

    environment = os.environ.copy()
    environment["VOIPCENTRA_LOCK_INHERITED"] = "1"

    print(
        "PASS: Secure deployment lock acquired and FD 9 prepared",
        flush=True
    )

    os.execvpe(command[0], command, environment)


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        print("SAFETY STOP:", exc, file=sys.stderr)
        sys.exit(1)
