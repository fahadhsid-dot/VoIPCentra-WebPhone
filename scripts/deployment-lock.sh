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

    # Validate the actual opened lock descriptor.
    voipcentra_validate_lock_fd() {
        local fd="$1"
        local metadata kind owner mode links

        metadata="$(stat -Lc '%F|%u|%a|%h' "/proc/self/fd/$fd")" || return 1
        IFS='|' read -r kind owner mode links <<< "$metadata"

        [[ "$kind" == "regular file" ||
           "$kind" == "regular empty file" ]] || return 1
        [[ "$owner" == "$(id -u)" ]] || return 1
        [[ "$links" == "1" ]] || return 1
        [[ "$mode" =~ ^[0-7]{3,4}$ ]] || return 1

        (( (8#$mode & 8#77) == 0 )) || return 1
    }

    # A child installer inherits the parent's locked descriptor.
    # Only trust the inherited descriptor when it references
    # the expected lock file and the current process holds its lock.
    if [[ "${VOIPCENTRA_LOCK_INHERITED:-}" == "1" ]]; then
        if [[ -e "/proc/self/fd/9" ]] &&
           [[ "$(readlink -f /proc/self/fd/9)" == "$(readlink -f "$lock_file")" ]]; then
            if ! voipcentra_validate_lock_fd 9; then
                echo "SAFETY STOP: Inherited lock metadata invalid."
                return 1
            fi

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

    if ! voipcentra_validate_lock_fd 9; then
        echo "SAFETY STOP: Deployment lock metadata invalid."
        exec 9>&-
        return 1
    fi

    if ! flock -n 9; then
        echo "SAFETY STOP: Another deployment is running."
        return 1
    fi

    export VOIPCENTRA_LOCK_INHERITED=1
    echo "PASS: Shared deployment lock acquired."
}
