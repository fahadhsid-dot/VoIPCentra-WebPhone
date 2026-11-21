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
    if not source.is_dir() or source.is_symlink():
        raise RuntimeError("Source must be a real directory")

    if source.parent.resolve() != target.parent.resolve():
        raise RuntimeError("Source and target must share a parent directory")

    if target.exists() or target.is_symlink():
        raise FileExistsError(errno.EEXIST, "Destination already exists", str(target))

    libc = ctypes.CDLL(None, use_errno=True)
    renameat2 = getattr(libc, "renameat2", None)

    if renameat2 is None:
        raise RuntimeError("renameat2 is unavailable")

    renameat2.argtypes = [
        ctypes.c_int,
        ctypes.c_char_p,
        ctypes.c_int,
        ctypes.c_char_p,
        ctypes.c_uint,
    ]
    renameat2.restype = ctypes.c_int

    result = renameat2(
        AT_FDCWD,
        os.fsencode(source),
        AT_FDCWD,
        os.fsencode(target),
        RENAME_NOREPLACE,
    )

    if result != 0:
        error = ctypes.get_errno()
        raise OSError(error, os.strerror(error), str(target))


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
