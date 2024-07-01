#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

install_unit() {
    local unit=$1; shift
    local target=${1:-initrd}
    inst_simple "$moddir/$unit" "$systemdsystemunitdir/$unit"
    # note we `|| exit 1` here so we error out if e.g. the units are missing
    # see https://github.com/coreos/fedora-coreos-config/issues/799
    systemctl -q --root="$initdir" add-requires "${target}.target" "$unit" || exit 1
}

install() {
    inst_script "$moddir/nestos-propagate-multipath-conf.sh" \
        "/usr/sbin/nestos-propagate-multipath-conf"

    install_unit nestos-propagate-multipath-conf.service

    inst_simple "$moddir/nestos-multipath-generator" \
        "$systemdutildir/system-generators/nestos-multipath-generator"

    # we don't enable these; they're enabled dynamically via the generator
    inst_simple "$moddir/nestos-multipath-wait.target" \
        "$systemdsystemunitdir/nestos-multipath-wait.target"
    inst_simple "$moddir/nestos-multipath-trigger.service" \
        "$systemdsystemunitdir/nestos-multipath-trigger.service"
}
