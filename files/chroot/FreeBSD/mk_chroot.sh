#!/bin/sh

# mk_chroot /path/to/chroot/dir devfs_rule_number

chroot_dir="$1"
chroot_dev_dir="${chroot_dir}/dev"
devfs_rule_number="$2"


mkdir -p "${chroot_dev_dir}"
mount -t devfs devfs "${chroot_dev_dir}"

# Create new ruleset
devfs -m "${chroot_dev_dir}" ruleset "${devfs_rule_number}"

# Add the rules
devfs -m "${chroot_dev_dir}" rule add 100 hide
devfs -m "${chroot_dev_dir}" rule add 200 path random  unhide
devfs -m "${chroot_dev_dir}" rule add 300 path urandom unhide

# Apply the ruleset
devfs -m "${chroot_dev_dir}" rule applyset
