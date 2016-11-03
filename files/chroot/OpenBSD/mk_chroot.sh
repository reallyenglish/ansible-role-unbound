#!/bin/sh
set -e

chroot_dir="$1"
chroot_dev_dir="${chroot_dir}/dev"
mount_mfs -s 256k -o nosuid swap "${chroot_dev_dir}"

(
  cd "${chroot_dev_dir}"; \
  mknod -m 644 random c 45 0; \
  mknod -m 666 null c 2 2; \
  mknod -m 666 zero c 2 12; \
  mknod -m 666 stdin c 22 0; \
  mknod -m 666 stdout c 22 1; \
  mknod -m 666 stderr c 22 2 \
)
