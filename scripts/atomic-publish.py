#!/usr/bin/env python3
"""Atomically publish a prepared directory without replacing any destination."""

import ctypes
import errno
import os
import sys
from pathlib import Path

AT_FDCWD = -100
RENAME_NOREPLACE = 1


def publish(source: Path, target: Path) -> None:
    import re
    import stat

    # This development publisher is restricted to isolated test roots.
    parent = source.parent
    root = str(parent)

    if not re.fullmatch(
        r"/tmp/voipcentra-dual-[A-Za-z0-9._-]+", root
    ):
        raise RuntimeError("Invalid isolated publish root")

    if ".." in parent.name:
        raise RuntimeError("Invalid publish root name")

    if parent != target.parent:
        raise RuntimeError("Source and target must share a parent")

    if not source.is_absolute() or not target.is_absolute():
        raise RuntimeError("Absolute paths required")

    if source.name == target.name:
        raise RuntimeError("Source and target must differ")

    flags = (
        os.O_RDONLY |
        os.O_DIRECTORY |
        os.O_NOFOLLOW |
        os.O_CLOEXEC
    )

    root_fd = os.open(root, flags)

    try:
        root_info = os.fstat(root_fd)

        if not stat.S_ISDIR(root_info.st_mode):
            raise RuntimeError("Publish root is not a directory")

        if root_info.st_uid != os.geteuid():
            raise RuntimeError("Publish root owner mismatch")

        if stat.S_IMODE(root_info.st_mode) & 0o022:
            raise RuntimeError("Publish root permissions unsafe")

        source_fd = os.open(
            source.name,
            flags,
            dir_fd=root_fd
        )

        try:
            info = os.fstat(source_fd)
            entry = os.stat(
                source.name,
                dir_fd=root_fd,
                follow_symlinks=False
            )

            if not stat.S_ISDIR(info.st_mode):
                raise RuntimeError("Source is not a directory")

            if info.st_uid != os.geteuid():
                raise RuntimeError("Source owner mismatch")

            if (
                info.st_dev != entry.st_dev or
                info.st_ino != entry.st_ino
            ):
                raise RuntimeError("Source directory changed")

            libc = ctypes.CDLL(None, use_errno=True)
            renameat2 = getattr(libc, "renameat2", None)

            if renameat2 is None:
                raise RuntimeError("renameat2 unavailable")

            renameat2.argtypes = [
                ctypes.c_int,
                ctypes.c_char_p,
                ctypes.c_int,
                ctypes.c_char_p,
                ctypes.c_uint,
            ]
            renameat2.restype = ctypes.c_int

            result = renameat2(
                root_fd,
                os.fsencode(source.name),
                root_fd,
                os.fsencode(target.name),
                RENAME_NOREPLACE
            )

            if result != 0:
                error = ctypes.get_errno()
                raise OSError(
                    error,
                    os.strerror(error),
                    str(target)
                )

            os.fsync(root_fd)

        finally:
            os.close(source_fd)

    finally:
        os.close(root_fd)


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: atomic-publish.py SOURCE TARGET", file=sys.stderr)
        sys.exit(2)

    try:
        publish(Path(sys.argv[1]), Path(sys.argv[2]))
        print("ATOMIC PUBLISH COMPLETE")
    except Exception as exc:
        print(f"SAFETY STOP: {exc}", file=sys.stderr)
        sys.exit(1)
