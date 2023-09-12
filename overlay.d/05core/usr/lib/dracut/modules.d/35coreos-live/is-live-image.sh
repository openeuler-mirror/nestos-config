#!/bin/sh
# Script invoked by ignition-dracut generator to detect whether this is a
# live system without a root device.  We can't test for /run/ostree-live
# because it's created by a generator.
# This file is created by nestos-assembler buildextend-live.
test -f /etc/nestos-live-initramfs
