# ansible-role-unbound

Configures `unbound`.

## Notes

The role does not cover all configuration options available in
`unbound.conf(5)`. The goal of the role is creating a role that reasonably
works out-of-box with minimum efforts. If you need to configure every options
supported in `unbound.conf(5)`, This is not for you.

## chroot support

When `unbound_config_chroot` is not empty, the role creates necessary files for
unbound. Supported platform includes:

* OpenBSD
* FreeBSD

# Requirements

None

# Role Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `unbound_user` | user of `unbound` | `{{ __unbound_user }}` |
| `unbound_group` | group of `unboun` | `{{ __unbound_group }}` |
| `unbound_service` | service name of `unbound` | `unbound` |
| `unbound_conf_dir` | path to config directory | `{{ __unbound_conf_dir }}` |
| `unbound_conf_file` | path to `unbound.conf(5)` | `{{ __unbound_conf_dir }}/unbound.conf` |
| `unbound_flags` | (not implemented yet) | `""` |
| `unbound_script_dir` | directory to install scripts in `files` | `{{ __unbound_script_dir }}` |
| `unbound_directory` | work directory of `unbound` | `{{ __unbound_directory }}` |
| `unbound_config_chroot` | path to `chroo(2)` directory | `""` |
| `unbound_freebsd_chroot_devfs_ruleset_number` | `devfs(8)` rule set number. Change when `unbound_config_chroot` is not empty and you have other `devfs(8)` rule set with the same number. | `100` |
| `unbound_config_interface` | `interface` to listen on | `[]` |
| `unbound_config_access_control` | list of `access-control` | `[]` |
| `unbound_config_private_address` | list of `private-address` | `["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16", "192.254.0.0/16", "fd00::/8", "fe80::/10"]` |
| `unbound_config_private_domain` | list of `private-domain` | `[]` |
| `unbound_config_server_extra` | list of extra settings in `server` section | `[]` |
| `unbound_config_remote_control_control_enable` | `control-enable` | `yes` |
| `unbound_config_remote_control_control_use_cert` | `control-use-cert` | `no` |
| `unbound_config_remote_control_control_interface` | `control-interface` | `""` |
| `unbound_config_server_key_file` | `server-key-file` | `{{ unbound_conf_dir }}/unbound_server.key` |
| `unbound_config_server_cert_file` | `server-cert-file` | `{{ unbound_conf_dir }}/unbound_server.pem` |
| `unbound_config_control_key_file` | `control-key-file` | `{{ unbound_conf_dir }}/unbound_control.key` |
| `unbound_config_control_cert_file` | `control-cert-file` | `{{ unbound_conf_dir }}/unbound_control.pem` |
| `unbound_config_remote_control_extra` | list of extra settings in `remote-control` | `[]` |
| `unbound_forward_zone` | TODO | `[]` |
| `unbound_stub_zone` | TODO | `[]` |

## Debian

| Variable | Default |
|----------|---------|
| `__unbound_user` | `unbound` |
| `__unbound_group` | `unbound` |
| `__unbound_conf_dir` | `/etc/unbound` |
| `__unbound_script_dir` | `/usr/bin` |
| `__unbound_directory` | `/etc/unbound` |

## FreeBSD

| Variable | Default |
|----------|---------|
| `__unbound_user` | `unbound` |
| `__unbound_group` | `unbound` |
| `__unbound_conf_dir` | `/usr/local/etc/unbound` |
| `__unbound_script_dir` | `/usr/local/bin` |
| `__unbound_directory` | `/usr/local/etc/unbound` |

## OpenBSD

| Variable | Default |
|----------|---------|
| `__unbound_user` | `_unbound` |
| `__unbound_group` | `_unbound` |
| `__unbound_conf_dir` | `/var/unbound/etc` |
| `__unbound_script_dir` | `/usr/local/bin` |
| `__unbound_directory` | `/var/unbound` |

## RedHat

| Variable | Default |
|----------|---------|
| `__unbound_user` | `unbound` |
| `__unbound_group` | `unbound` |
| `__unbound_conf_dir` | `/etc/unbound` |
| `__unbound_script_dir` | `/usr/bin` |
| `__unbound_directory` | `/etc/unbound` |

# Dependencies

None

# Example Playbook

```yaml
- hosts: localhost
  roles:
    - ansible-role-unbound
  vars:
    unbound_config_chroot: ""
    unbound_config_interface:
      - "{{ ansible_default_ipv4.address }}"
    unbound_config_outgoing_interface: "{{ ansible_default_ipv4.address }}"
    unbound_config_access_control:
      - 0.0.0.0/0 refuse
      - 127.0.0.0/8 allow
      - 10.100.1.0/24 allow
    unbound_config_private_domain:
      - example.com
    # unbound in ubuntu 14.04 does not support unix socket
    unbound_config_remote_control_control_interface: "{% if (ansible_distribution == 'Ubuntu' and ansible_distribution_version | version_compare('14.04', '<=')) or (ansible_distribution == 'CentOS' and ansible_distribution_version | version_compare('7.3.1611', '<=')) %}127.0.0.1{% else %}/var/run/unbound.sock{% endif %}"
    unbound_forward_zone:
      -
        name: example.com
        forward_addr:
          - 8.8.8.8
      -
        name: example.org
        forward_addr:
          - 8.8.8.8
    unbound_stub_zone:
      - name: example.net
        stub_addr:
          - 8.8.8.8
      - name: foo.example
        stub_addr:
          - 8.8.8.8
```

# License

```
Copyright (c) 2016 Tomoyuki Sakurai <tomoyukis@reallyenglish.com>

Permission to use, copy, modify, and distribute this software for any
purpose with or without fee is hereby granted, provided that the above
copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
```

# Author Information

Tomoyuki Sakurai <tomoyukis@reallyenglish.com>

This README was created by [ansible-role-init](https://gist.github.com/trombik/d01e280f02c78618429e334d8e4995c0)
