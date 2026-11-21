#!/usr/bin/env python3
"""Test-only VoIPCentra transaction journal."""

import json
import os
import sys
import tempfile
from datetime import datetime, timezone
from pathlib import Path

ALLOWED = {
    "STARTED",
    "PREMIUM_INSTALLED",
    "ORIGINAL_INSTALLED",
    "COMPLETE",
    "FAILED",
}

TRANSITIONS = {
    None: {"STARTED"},
    "STARTED": {"PREMIUM_INSTALLED", "FAILED"},
    "PREMIUM_INSTALLED": {"ORIGINAL_INSTALLED", "FAILED"},
    "ORIGINAL_INSTALLED": {"COMPLETE", "FAILED"},
    "COMPLETE": set(),
    "FAILED": set(),
}

def main():
    if len(sys.argv) != 4:
        raise RuntimeError("Usage: transaction-journal.py ROOT TX_ID STATE")

    root = Path(sys.argv[1])
    tx_id = sys.argv[2]
    state = sys.argv[3]

    if os.environ.get("VOIPCENTRA_TEST_MODE") != "1":
        raise RuntimeError("Journal is test-only")

    if (
        root.parent != Path("/tmp")
        or not root.name.startswith("voipcentra-dual-")
        or not root.name[len("voipcentra-dual-"):].replace("-", "").replace("_", "").replace(".", "").isalnum()
        or ".." in root.name
    ):
        raise RuntimeError("Invalid test root")

    if not root.is_dir() or root.is_symlink():
        raise RuntimeError("Invalid test directory")

    if len(tx_id) != 32 or any(c not in "0123456789abcdef" for c in tx_id):
        raise RuntimeError("Invalid transaction ID")

    if state not in ALLOWED:
        raise RuntimeError("Invalid transaction state")

    journal = root / (".voipcentra-transaction-" + tx_id + ".json")

    if journal.is_symlink():
        raise RuntimeError("Journal symlink rejected")

    if journal.exists():
        with journal.open("r") as handle:
            previous = json.load(handle)

        if previous.get("transaction_id") != tx_id:
            raise RuntimeError("Transaction ID mismatch")

        history = previous.get("history", [])
        current = previous.get("current_state")

        if not isinstance(history, list):
            raise RuntimeError("Invalid journal history")
    else:
        history = []
        current = None

    if state not in TRANSITIONS.get(current, set()):
        raise RuntimeError(
            "Invalid state transition: {} -> {}".format(current, state)
        )

    history.append({
        "state": state,
        "timestamp": datetime.now(timezone.utc).isoformat(),
    })

    data = {
        "transaction_id": tx_id,
        "current_state": state,
        "history": history,
    }

    fd, temporary = tempfile.mkstemp(
        prefix=".voipcentra-journal-",
        dir=str(root)
    )

    try:
        with os.fdopen(fd, "w") as handle:
            json.dump(data, handle, indent=2)
            handle.flush()
            os.fsync(handle.fileno())

        os.replace(temporary, str(journal))
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)

    print("JOURNAL STATE:", state)


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        print("SAFETY STOP:", exc, file=sys.stderr)
        sys.exit(1)
