#!/bin/sh

# A wrapper for unbound(8). Prefixed with "ansible-" because this wraper is
# created to solve an issue caused by ansible implementation.
#
# unbound-checkconf failes if a file, not inside of chroot, is given.
#
# [1477271430] unbound-checkconf[88482:0] fatal error: config file /home/vagrant/./unbound.conf is not inside chroot /var/unbound
#
# when "validate" is give in a task, ansble copies the file to valiadate to its
# tmp directory.
#
# This wrapper safely copies the given file to "directory:" in unbound.conf(5)
# and validate it.
#
# BUG does not handle chroot yet

ensure()
{
    rm -f "${tmp_file}"
}

trap ensure 1 2 3 15

config_file_to_validate="${1}"
version=`unbound-checkconf -h | grep -e '^Version' | cut -f 2 -d ' ' | cut -f 1,2 -d '.'`

case "${version}" in
    1.4)    option="-o directory" ;;
    *)      option="-f -o directory" ;;
esac

etc_dir=`unbound-checkconf ${option} "${config_file_to_validate}"`
echo "${etc_dir}"

tmp_file=`mktemp "${etc_dir}/unbound.conf.XXXXXXXXXXX"` || exit 1
cp "${config_file_to_validate}" "${tmp_file}"
unbound-checkconf "${tmp_file}"
rm -f "${tmp_file}"
