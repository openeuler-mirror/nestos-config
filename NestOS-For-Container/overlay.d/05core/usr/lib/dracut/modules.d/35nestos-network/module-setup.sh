install_and_enable_unit() {
    unit="$1"; shift
    target="$1"; shift
    inst_simple "$moddir/$unit" "$systemdsystemunitdir/$unit"
    # note we `|| exit 1` here so we error out if e.g. the units are missing
    # see https://github.com/coreos/fedora-coreos-config/issues/799
    systemctl -q --root="$initdir" add-requires "$target" "$unit" || exit 1
}

install() {
    inst_simple "$moddir/nestos-enable-network.sh" \
        "/usr/sbin/nestos-enable-network"
    install_and_enable_unit "nestos-enable-network.service" \
        "initrd.target"

    inst_simple "$moddir/nestos-copy-firstboot-network.sh" \
        "/usr/sbin/nestos-copy-firstboot-network"
    # Only run this when ignition runs and only when the system
    # has disks. ignition-diskful.target should suffice.
    install_and_enable_unit "nestos-copy-firstboot-network.service" \
        "ignition-diskful.target"

    # Dropin with firstboot network configuration kargs, applied via
    # Afterburn.
    inst_simple "$moddir/50-afterburn-network-kargs-default.conf" \
        "/usr/lib/systemd/system/afterburn-network-kargs.service.d/50-afterburn-network-kargs-default.conf"

}
