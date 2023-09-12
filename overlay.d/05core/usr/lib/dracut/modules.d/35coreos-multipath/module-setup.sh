#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

install_ignition_unit() {
    local unit=$1; shift
    local target=${1:-complete}
    inst_simple "$moddir/$unit" "$systemdsystemunitdir/$unit"
    # note we `|| exit 1` here so we error out if e.g. the units are missing
    # see https://github.com/coreos/fedora-coreos-config/issues/799
    systemctl -q --root="$initdir" add-requires "ignition-${target}.target" "$unit" || exit 1
}

install() {
    inst_script "$moddir/coreos-propagate-multipath-conf.sh" \
        "/usr/sbin/coreos-propagate-multipath-conf"

    install_ignition_unit coreos-propagate-multipath-conf.service subsequent

    inst_simple "$moddir/nestos-multipath-generator" \
        "$systemdutildir/system-generators/nestos-multipath-generator"

    # we don't enable these; they're enabled dynamically via the generator
    inst_simple "$moddir/nestos-multipath-wait.target" \
        "$systemdsystemunitdir/nestos-multipath-wait.target"
    inst_simple "$moddir/nestos-multipath-trigger.service" \
        "$systemdsystemunitdir/nestos-multipath-trigger.service"
}
