#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

set -euo pipefail

# Load dracut libraries. Using getargbool() and getargs() from
# dracut-lib and ip_to_var() from net-lib
load_dracut_libs() {
    # dracut is not friendly to set -eu
    set +euo pipefail
    type getargbool &>/dev/null || . /lib/dracut-lib.sh
    type ip_to_var &>/dev/null  || . /lib/net-lib.sh
    set -euo pipefail
}

dracut_func() {
    # dracut is not friendly to set -eu
    set +euo pipefail
    "$@"; local rc=$?
    set -euo pipefail
    return $rc
}

# Get the BOOTIF and rd.bootif kernel arguments from
# the kernel command line.
get_bootif_kargs() {
    bootif_kargs=""
    bootif_karg=$(dracut_func getarg BOOTIF)
    if [ ! -z "$bootif_karg" ]; then
        bootif_kargs+="BOOTIF=${bootif_karg}"
    fi
    rdbootif_karg=$(dracut_func getarg rd.bootif)
    if [ ! -z "$rdbootif_karg" ]; then
        bootif_kargs+=" rd.bootif=${rdbootif_karg}"
    fi
    echo $bootif_kargs
}

# Determine if the generated NM connection profiles match the default
# that would be given to us if the user had provided no additional
# configuration. i.e. did the user give us any network configuration
# other than the default? We determine this by comparing the generated
# output of nm-initrd-generator with a new run of nm-initrd-generator.
# If it matches then it was the default, if not then the user provided
# something extra.
are_default_NM_configs() {
    # pick up our NestOS default networking kargs from the afterburn dropin
    DEFAULT_KARGS_FILE=/usr/lib/systemd/system/afterburn-network-kargs.service.d/50-afterburn-network-kargs-default.conf
    source <(grep -o 'AFTERBURN_NETWORK_KARGS_DEFAULT=.*' $DEFAULT_KARGS_FILE)
    # Also pick up BOOTIF/rd.bootif kargs and apply them here.
    # See https://github.com/coreos/fedora-coreos-tracker/issues/1048
    BOOTIF_KARGS=$(get_bootif_kargs)
    # Make two dirs for storing files to use in the comparison
    mkdir -p /run/nestos-teardown-initramfs/connections-compare-{1,2}
    # Make another that's just a throwaway for the initrd-data-dir
    mkdir -p /run/nestos-teardown-initramfs/initrd-data-dir
    # Copy over the previously generated connection(s) profiles
    cp  /run/NetworkManager/system-connections/* \
        /run/nestos-teardown-initramfs/connections-compare-1/
    # Delete lo.nmconnection if it was created.
    # https://github.com/coreos/fedora-coreos-tracker/issues/1385
    rm -f /run/nestos-teardown-initramfs/connections-compare-1/lo.nmconnection
    # Do a new run with the default input
    /usr/libexec/nm-initrd-generator \
        -c /run/nestos-teardown-initramfs/connections-compare-2 \
        -i /run/nestos-teardown-initramfs/initrd-data-dir \
        -- $AFTERBURN_NETWORK_KARGS_DEFAULT $BOOTIF_KARGS
    # remove unique identifiers from the files (so our diff can work)
    sed -i '/^uuid=/d' /run/nestos-teardown-initramfs/connections-compare-{1,2}/*
    # currently the output will differ based on whether rd.neednet=1
    # was part of the kargs. Let's ignore the single difference (wait-device-timeout)
    sed -i '/^wait-device-timeout=/d' /run/nestos-teardown-initramfs/connections-compare-{1,2}/*
    if diff -r -q /run/nestos-teardown-initramfs/connections-compare-{1,2}/; then
        rc=0 # They are the default configs
    else
        rc=1 # They are not the defaults, user must have added configuration
    fi
    rm -rf /run/nestos-teardown-initramfs
    return $rc
}

# Propagate initramfs networking if desired. The policy here is:
#
#    - If a networking configuration was provided before this point
#      (most likely via Ignition) and exists in the real root then
#      we do nothing and don't propagate any initramfs networking.
#    - If a user did not provide any networking configuration
#      then we'll propagate the initramfs networking configuration
#      into the real root, but only if it's different than the NM
#      defaults (trying dhcp/dhcp6 on everything). If it's just the
#      defaults then we want to avoid a slight behavior diff between
#      propagating configs and just booting with no configuration. See
#      https://github.com/coreos/fedora-coreos-tracker/issues/696
#
# See https://github.com/coreos/fedora-coreos-tracker/issues/394#issuecomment-599721173
propagate_initramfs_networking() {
    # Check for any real root config in the two locations where a user could have
    # provided network configuration. On FCOS we only support keyfiles, but on RHCOS
    # we support keyfiles and ifcfg. We also need to ignore readme-ifcfg-rh.txt
    # which is a cosmetic file added in
    # https://gitlab.freedesktop.org/NetworkManager/NetworkManager/-/commit/96d7362
    if [ -n "$(ls -A /sysroot/etc/NetworkManager/system-connections/)" -o \
         -n "$(ls -A -I readme-ifcfg-rh.txt /sysroot/etc/sysconfig/network-scripts/)" ]; then
        echo "info: networking config is defined in the real root"
        realrootconfig=1
    else
        echo "info: no networking config is defined in the real root"
        realrootconfig=0
    fi

    # Did the user tell us to force initramfs networking config
    # propagation even if real root networking config exists?
    # Hopefully we only need this in rare circumstances.
    # https://github.com/coreos/fedora-coreos-tracker/issues/853
    forcepropagate=0
    if dracut_func getargbool 0 'nestos.force_persist_ip'; then
        forcepropagate=1
        echo "info: nestos.force_persist_ip detected: will force network config propagation"
    fi

    if [ $realrootconfig == 1 -a $forcepropagate == 0 ]; then
        echo "info: will not attempt to propagate initramfs networking"
    fi

    if [ $realrootconfig == 0 -o $forcepropagate == 1 ]; then
        if [ -n "$(ls -A /run/NetworkManager/system-connections/)" ]; then
            if are_default_NM_configs; then
                echo "info: skipping propagation of default networking configs"
            else
                echo "info: propagating initramfs networking config to the real root"
                cp -v /run/NetworkManager/system-connections/* /sysroot/etc/NetworkManager/system-connections/
                # Delete lo.nmconnection if it was created.
                # https://github.com/coreos/fedora-coreos-tracker/issues/1385
                rm -vf /sysroot/etc/NetworkManager/system-connections/lo.nmconnection
                nestos-relabel /etc/NetworkManager/system-connections/
            fi
        else
            echo "info: no initramfs networking information to propagate"
        fi
    fi
}

# Propagate the ip= karg hostname if desired. The policy here is:
#
#     - IF a hostname was detected in ip= kargs by NetworkManager
#     - AND no hostname was set via Ignition (realroot `/etc/hostname`)
#     - THEN we make the hostname detected by NM apply permanently
#       by writing it into `/etc/hostname`
#
propagate_initramfs_hostname() {
    if [ -e '/sysroot/etc/hostname' ]; then
        echo "info: hostname is defined in the real root"
        echo "info: will not attempt to propagate initramfs hostname"
        return 0
    fi

    # If any hostname was provided NetworkManager will write it out to
    # /run/NetworkManager/initrd/hostname. See
    # https://gitlab.freedesktop.org/NetworkManager/NetworkManager/-/merge_requests/481
    if [ -s /run/NetworkManager/initrd/hostname ]; then
        hostname=$(</run/NetworkManager/initrd/hostname)
        echo "info: propagating initramfs hostname (${hostname}) to the real root"
        echo $hostname > /sysroot/etc/hostname
        nestos-relabel /etc/hostname
    else
        echo "info: no initramfs hostname information to propagate"
    fi
}

# Propagate the ifname= karg udev rules. The policy here is:
#
#     - IF ifname karg udev rule file exists
#     - THEN copy it to the real root
#
propagate_ifname_udev_rules() {
    local udev_file='/etc/udev/rules.d/80-ifname.rules'
    if [ -e "${udev_file}" ]; then
        echo "info: propagating ifname karg udev rules to the real root"
        cp -v "${udev_file}" "/sysroot/${udev_file}"
        nestos-relabel "${udev_file}"
    fi
}

down_interface() {
    echo "info: taking down network device: $1"
    # On recommendation from the NM team let's try to delete the device
    # first and if that doesn't work then set it to down and flush any
    # associated addresses. Deleting virtual devices (bonds, teams, bridges,
    # ip-tunnels, etc) will clean up any associated kernel resources. A real
    # device can't be deleted so that will fail and we'll fallback to setting
    # it down and flushing addresses.
    if ! ip link delete $1; then
        ip link set $1 down
        ip addr flush dev $1
    fi
}

# Iterate through the interfaces in the machine and take them down.
# Note that in the future we would like to possibly use `nmcli` networking off`
# for this. See the following two comments for details:
# https://github.com/coreos/fedora-coreos-tracker/issues/394#issuecomment-599721763
# https://github.com/coreos/fedora-coreos-tracker/issues/394#issuecomment-599746049
down_interfaces() {
    if ! [ -z "$(ls /sys/class/net)" ]; then
        for f in /sys/class/net/*; do
            interface=$(basename "$f")
            # The `bonding_masters` entry is not a true interface and thus
            # cannot be taken down. Also skip local loopback
            case "$interface" in
                "lo" | "bonding_masters")
                    continue
                    ;;
            esac
            # When we start taking down devices some other devices can
            # start to disappear (for example vlan on top of interface).
            # If the device we're about to take down has disappeared
            # since the start of this loop then skip taking it down.
            if [ ! -e "$f" ]; then
                echo "info: skipping teardown of ${interface}; no longer exists."
                continue
            fi
            down_interface $interface
        done
    fi
}

main() {
    # Load libraries from dracut
    load_dracut_libs

    # If we're using iSCSI, then we can't tear down networking since we'll lose
    # root. This means in that case that the network config written to the real
    # root won't be applied "from scratch". But anyway, since networking must
    # stay on, it's simply not supported to configure the real root in a way
    # that would require tearing down the connection on the interface involved.
    if dracut_func getargbool 0 rd.iscsi.firmware || dracut_func getarg netroot; then
        echo "info: iSCSI in use; not tearing down networking"
    else
        # Take down all interfaces set up in the initramfs
        down_interfaces

        # Clean up all routing
        echo "info: flushing all routing"
        ip route flush table main
        ip route flush cache
    fi

    # Hopefully our logic is sound enough that this is never needed, but
    # user's can explicitly disable initramfs network/hostname propagation
    # with the nestos.no_persist_ip karg.
    if dracut_func getargbool 0 'nestos.no_persist_ip'; then
        echo "info: nestos.no_persist_ip karg detected"
        echo "info: skipping propagating initramfs settings"
    else
        propagate_initramfs_hostname
        propagate_initramfs_networking
        propagate_ifname_udev_rules
    fi

    # Now that the configuration has been propagated (or not)
    # clean it up so that no information from outside of the
    # real root is passed on to NetworkManager in the real root
    rm -rf /run/NetworkManager/

    rm -f /run/udev/rules.d/80-nestos-boot-disk.rules
    rm -f /dev/disk/by-id/nestos-boot-disk
}

main
