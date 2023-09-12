depends() {
    # We need the rdcore binary
    echo rdcore
}

install_and_enable_unit() {
    unit="$1"; shift
    target="$1"; shift
    inst_simple "$moddir/$unit" "$systemdsystemunitdir/$unit"
    # note we `|| exit 1` here so we error out if e.g. the units are missing
    # see https://github.com/coreos/fedora-coreos-config/issues/799
    systemctl -q --root="$initdir" add-requires "$target" "$unit" || exit 1
}

installkernel() {
    # we do loopmounts
    instmods -c loop
}

install() {
    inst_multiple \
        bsdtar \
        curl \
        truncate

    inst_script "$moddir/is-live-image.sh" \
        "/usr/bin/is-live-image"

    inst_script "$moddir/ostree-cmdline.sh" \
        "/usr/sbin/ostree-cmdline"

    inst_simple "$moddir/live-generator" \
        "$systemdutildir/system-generators/live-generator"

    inst_simple "$moddir/nestos-live-unmount-tmpfs-var.sh" \
        "/usr/sbin/nestos-live-unmount-tmpfs-var"

    inst_simple "$moddir/nestos-livepxe-rootfs.sh" \
        "/usr/sbin/nestos-livepxe-rootfs"

    install_and_enable_unit "nestos-live-unmount-tmpfs-var.service" \
        "initrd-switch-root.target"

    install_and_enable_unit "nestos-livepxe-rootfs.service" \
        "initrd-root-fs.target"

    install_and_enable_unit "nestos-live-clear-sssd-cache.service" \
        "ignition-complete.target"

    install_and_enable_unit "nestos-liveiso-persist-osmet.service" \
        "default.target"

    install_and_enable_unit "nestos-livepxe-persist-osmet.service" \
        "default.target"
}
