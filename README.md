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

# Requirements

None

# Role Variables

| Variable | Description | Default |
|----------|-------------|---------|
| unbound\_user | user of unbound | {{ \_\_unbound\_user }} |
| unbound\_group | group of unbound | {{ \_\_unbound\_group }} |
| unbound\_service | service name | unbound |
| unbound\_conf\_dir | path to dir of config directory | {{ \_\_unbound\_conf\_dir }} |
| unbound\_conf\_file | path to `unbound.conf(5)` | {{ \_\_unbound\_conf\_dir }}/unbound.conf |
| unbound\_flags | unused | "" |
| unbound\_script\_dir | directory to install scripts in `files` | {{ \_\_unbound\_script\_dir }} |
| unbound\_directory | work directory | {{ \_\_unbound\_directory }} |
| unbound\_config\_chroot | path to chroot directory | "" |
| unbound\_script\_dir | directory to keep support script. this must be included in PATH environment variable. | {{ \_\_unbound\_script\_dir }} |
| unbound\_config\_interface | `interface` to listen on | [] |
| unbound\_config\_outgoing\_interface | `outgoing-interface` | "" |
| unbound\_config\_do\_not\_query\_localhost | `do-not-query-localhost` | yes |
| unbound\_config\_do\_ip4 | `do-ip4` | yes |
| unbound\_config\_do\_ip6 | `do-ip6` | no |
| unbound\_config\_access\_control | `access-control` | [] |
| unbound\_config\_hide\_identity | `hide-identity` | yes |
| unbound\_config\_hide\_version | `hide-version` | yes |
| unbound\_config\_use\_syslog | `use-syslog` | yes |
| unbound\_config\_private\_address | `private-address` | ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16", "192.254.0.0/16", "fd00::/8", "fe80::/10"] |
| unbound\_config\_private\_domain | `private-domain` | [] |
| unbound\_config\_remote\_control\_control\_enable | `control-enable` | yes |
| unbound\_config\_remote\_control\_control\_use\_cert | `control-use-cert` | no |
| unbound\_config\_remote\_control\_control\_interface | `control-interface` | "" |
| unbound\_config\_server\_key\_file | `server-key-file` | {{ unbound\_config\_directory }}/unbound\_server.key |
| unbound\_config\_server\_cert\_file | `server-cert-file` | {{ unbound\_config\_directory }}/unbound\_server.pem |
| unbound\_config\_control\_key\_file | `control-key-file` | {{ unbound\_config\_directory }}/unbound\_control.key |
| unbound\_config\_control\_cert\_file | `control-cert-file` | {{ unbound\_config\_directory }}/unbound\_control.pem |
| unbound\_forward\_zone | `forward-zone` | [] |

## Debian

| Variable | Default |
|----------|---------|
| \_\_unbound\_user | unbound |
| \_\_unbound\_group | unbound |
| \_\_unbound\_conf\_dir | /etc/unbound |
| \_\_unbound\_script\_dir | /usr/bin |
| \_\_unbound\_directory | /etc/unbound |

## FreeBSD

| Variable | Default |
|----------|---------|
| \_\_unbound\_user | unbound |
| \_\_unbound\_group | unbound |
| \_\_unbound\_conf\_dir | /usr/local/etc/unbound |
| \_\_unbound\_script\_dir | /usr/local/bin |
| \_\_unbound\_directory | /usr/local/etc/unbound |

## OpenBSD

| Variable | Default |
|----------|---------|
| \_\_unbound\_user | \_unbound |
| \_\_unbound\_group | \_unbound |
| \_\_unbound\_conf\_dir | /var/unbound/etc |
| \_\_unbound\_script\_dir | /usr/local/bin |
| \_\_unbound\_directory | /var/unbound |

## RedHat

| Variable | Default |
|----------|---------|
| \_\_unbound\_user | unbound |
| \_\_unbound\_group | unbound |
| \_\_unbound\_conf\_dir | /etc/unbound |
| \_\_unbound\_script\_dir | /usr/bin |
| \_\_unbound\_directory | /etc/unbound |

Created by [yaml2readme.rb](https://gist.github.com/trombik/b2df709657c08d845b1d3b3916e592d3)

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
    unbound_config_remote_control_control_interface: "{% if (ansible_distribution == 'Ubuntu' and ansible_distribution_version | version_compare('14.04', '<=')) or (ansible_distribution == 'CentOS' and ansible_distribution_version | version_compare('7.2.1511', '<=')) %}127.0.0.1{% else %}/var/run/unbound.sock{% endif %}"
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
