#!/bin/bash
set -xeuo pipefail

# Tests that rootless podman containers can DNS resolve external domains.
# https://github.com/coreos/fedora-coreos-tracker/issues/923
# kola: { "tags": "needs-internet", "platforms": "qemu-unpriv", "exclusive": false}

ok() {
    echo "ok" "$@"
}

fatal() {
    echo "$@" >&2
    exit 1
}

runascoreuserscript='
#!/bin/bash
set -euxo pipefail

sudo podman network create testnetwork
sudo podman run --rm -t --privileged --network=testnetwork hub.oepkgs.net/openeuler/openeuler:22.03-lts-sp3 getent hosts google.com
sudo podman network rm testnetwork
'

runascoreuser() {
    # NOTE: If we don't use `| cat` the output won't get copied
    # and won't show up in the output of the ext test.
    sudo -u nest "$@" | cat
}

main() {
    echo "$runascoreuserscript" > /tmp/runascoreuserscript
    chmod +x /tmp/runascoreuserscript
    if ! runascoreuser /tmp/runascoreuserscript ; then 
        fatal "DNS in rootless podman testnetwork failed. Test Fails" 
    else 
        ok "DNS in rootless podman testnetwork Suceeded. Test Passes" 
    fi
}

main
