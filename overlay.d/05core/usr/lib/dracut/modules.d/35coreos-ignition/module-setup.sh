#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

depends() {
    echo systemd network ignition coreos-live
}

install_ignition_unit() {
    local unit="$1"; shift
    local target="${1:-ignition-complete.target}"; shift
    local instantiated="${1:-$unit}"; shift
    inst_simple "$moddir/$unit" "$systemdsystemunitdir/$unit"
    # note we `|| exit 1` here so we error out if e.g. the units are missing
    # see https://github.com/coreos/fedora-coreos-config/issues/799
    systemctl -q --root="$initdir" add-requires "$target" "$instantiated" || exit 1
}

install() {
    inst_multiple \
        basename \
        diff \
        lsblk \
        sed \
        sgdisk

    inst_simple "$moddir/nestos-diskful-generator" \
        "$systemdutildir/system-generators/nestos-diskful-generator"

    inst_script "$moddir/nestos-gpt-setup.sh" \
        "/usr/sbin/nestos-gpt-setup"

    inst_script "$moddir/nestos-ignition-setup-user.sh" \
        "/usr/sbin/nestos-ignition-setup-user"

    # For consistency tear down the network and persist multipath between the initramfs and
    # real root. See https://github.com/coreos/fedora-coreos-tracker/issues/394#issuecomment-599721763
    inst_script "$moddir/coreos-teardown-initramfs.sh" \
        "/usr/sbin/coreos-teardown-initramfs"
    install_ignition_unit coreos-teardown-initramfs.service

    # units only started when we have a boot disk
    # path generated by systemd-escape --path /dev/disk/by-label/root
    install_ignition_unit nestos-gpt-setup.service ignition-diskful.target

    # dracut inst_script doesn't allow overwrites and we are replacing
    # the default script placed by Ignition
    binpath="/usr/sbin/ignition-kargs-helper"
    cp "$moddir/coreos-kargs.sh" "$initdir$binpath"
    install_ignition_unit coreos-kargs-reboot.service

    inst_script "$moddir/nestos-boot-edit.sh" \
        "/usr/sbin/nestos-boot-edit"
    # Only start when the system has disks since we are editing /boot.
    install_ignition_unit "nestos-boot-edit.service" \
        "ignition-diskful.target"

    install_ignition_unit nestos-ignition-setup-user.service
}
