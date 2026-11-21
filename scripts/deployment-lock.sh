#!/usr/bin/env bash

# Shared VoIPCentra deployment locking helper.
# Must be sourced by installation scripts.

voipcentra_acquire_lock() {
    local root="$1"
    local lock_file="$root/.voipcentra-deploy.lock"

    command -v flock >/dev/null 2>&1 || {
        echo "ERROR: flock command missing."
        return 1
    }

    [[ -d "$root" && ! -L "$root" ]] || {
        echo "SAFETY STOP: Invalid deployment root."
        return 1
    }

    # A child installer inherits the parent's locked descriptor.
    # Only trust the inherited descriptor when it references
    # the expected lock file and the current process holds its lock.
    if [[ "${VOIPCENTRA_LOCK_INHERITED:-}" == "1" ]]; then
        if [[ -e "/proc/self/fd/9" ]] &&
           [[ "$(readlink -f /proc/self/fd/9)" == "$(readlink -f "$lock_file")" ]]; then
            # Recheck flock on the inherited file description.
            # A forged environment flag alone must not bypass locking.
            if flock -n 9; then
                echo "PASS: Shared deployment lock inherited and verified."
                return 0
            fi

            echo "SAFETY STOP: Inherited lock verification failed."
            return 1
        fi

        echo "SAFETY STOP: Invalid inherited deployment lock."
        return 1
    fi

    umask 077

    [[ ! -L "$lock_file" ]] || {
        echo "SAFETY STOP: Lock path is a symlink."
        return 1
    }

    exec 9>>"$lock_file"

    if ! flock -n 9; then
        echo "SAFETY STOP: Another deployment is running."
        return 1
    fi

    export VOIPCENTRA_LOCK_INHERITED=1
    echo "PASS: Shared deployment lock acquired."
}
