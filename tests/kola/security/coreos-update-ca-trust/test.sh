#!/bin/bash
## kola:
##   exclusive: false
##   description: Verify that nestos-update-ca-trust service works.

set -xeuo pipefail

# shellcheck disable=SC1091
. "$KOLA_EXT_DATA/commonlib.sh"

# Make sure that nestos-update-ca-trust kicked in and observe the result.
if ! systemctl show nestos-update-ca-trust.service -p ActiveState | grep ActiveState=active; then
    fatal "nestos-update-ca-trust.service not active"
fi
if ! grep '^# nestos.com$' /etc/pki/ca-trust/extracted/openssl/ca-bundle.trust.crt; then
    fatal "expected nestos.com in ca-bundle"
fi
ok "nestos-update-ca-trust.service"
