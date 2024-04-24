#!/bin/bash
set -xeuo pipefail

ok() {
    echo "ok" "$@"
}

fatal() {
    echo "$@" >&2
    exit 1
}

#Testing that a user password provisioned by ignition works
OUTPUT=$(echo 'foobar' | setsid su - tester -c id)

if [[ $OUTPUT != "uid=1001(tester) gid=1001(tester) groups=1001(tester) context=system_u:system_r:unconfined_service_t:s0" ]]; then
    fatal "Failure when checking command output running with specified username and password"
fi
ok "User-password provisioned and passwd command successfully tested"