#!/bin/sh

# Create chroot environment for unbound
#
# chroot_unbound_enable (bool): Set "YES" to create chroot directory for
#                               unbound. Set to "NO" by default.
# chroot_unbound_flags: "/path/to/chroot $devfs_rule_number"
# chroot_unbound_flags="/usr/local/etc/unbound 100"
#
# PROVIDE: chroot_unbound
# BEFORE: unbound

. /etc/rc.subr

name="chroot_unbound"
rcvar="chroot_unbound_enable"

command="/usr/local/bin/mk_chroot"
command_args="${chroot_unbound_flags}"

load_rc_config $name

: ${chroot_unbound_enable="NO"}
: ${chroot_unbound_flags="/usr/local/etc/unbound 100"}

run_rc_command "$1"
