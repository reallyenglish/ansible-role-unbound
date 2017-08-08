# ansible-role-unbound

Configures `unbound`.

## chroot support

When `unbound_config_chroot` is not empty, the role creates necessary files for
unbound. Supported platform includes:

* OpenBSD
* FreeBSD

The implementation of `unbound_config_chroot` is quite hackish and is subject
to change.

See `tests/serverspec/chroot.yml` for the details.

# Requirements

None

# Role Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `unbound_user` | user of `unbound` | `{{ __unbound_user }}` |
| `unbound_group` | group of `unbound` | `{{ __unbound_group }}` |
| `unbound_service` | service name of `unbound` | `unbound` |
| `unbound_conf_dir` | path to config directory | `{{ __unbound_conf_dir }}` |
| `unbound_conf_file` | path to `unbound.conf(5)` | `{{ unbound_conf_dir }}/unbound.conf` |
| `unbound_flags` | dict of variables and their values in startup scripts. this variable is combined with `unbound_flags_default` (see below). | `{}` |
| `unbound_flags_default` | dict of default variables and their values in startup scripts | `{{ __unbound_flags_default }}` |
| `unbound_script_dir` | directory to install scripts in `files` | `{{ __unbound_script_dir }}` |
| `unbound_directory` | work directory of `unbound` | `{{ __unbound_directory }}` |
| `unbound_include_role_x509_certificate` | include and execute `reallyenglish.x509-certificate` when true | `no` |
| `unbound_config_chroot` | path to `chroo(2)` directory | `""` |
| `unbound_freebsd_chroot_devfs_ruleset_number` | `devfs(8)` rule set number. Change when `unbound_config_chroot` is not empty and you have other `devfs(8)` rule set with the same number. | `100` |
| `unbound_config_server` | list of settings in `server` section (see below) | `[]` |
| `unbound_config_remote_control_control_enable` | `control-enable` | `yes` |
| `unbound_config_remote_control_control_use_cert` | `control-use-cert` | `no` |
| `unbound_config_remote_control_control_interface` | `control-interface` | `""` |
| `unbound_config_server_key_file` | `server-key-file` | `{{ unbound_conf_dir }}/unbound_server.key` |
| `unbound_config_server_cert_file` | `server-cert-file` | `{{ unbound_conf_dir }}/unbound_server.pem` |
| `unbound_config_control_key_file` | `control-key-file` | `{{ unbound_conf_dir }}/unbound_control.key` |
| `unbound_config_control_cert_file` | `control-cert-file` | `{{ unbound_conf_dir }}/unbound_control.pem` |
| `unbound_config_remote_control_extra` | list of extra settings in `remote-control` | `[]` |
| `unbound_forward_zone` | list of settings in `forward-zone` (see below) | `[]` |
| `unbound_stub_zone` | list of settings in `stub-zone` (see below) | `[]` |

## `unbound_flags`

This variable is a dict of variables of startup configuration files, such as
files under `/etc/default`, `/etc/sysconfig`, and `/etc/rc.conf.d`. It is
assumed that the files are `source`d by startup mechanism with `sh(1)`. A key
in the dict is name of the variable in the file, and the value of the key is
value of the variable. The variable is combined with a variable whose name is
same as this variable, but postfixed with `_default` (explained below) and the
result creates the startup configuration file, usually a file consisting of
lines of `key="value"` under appropriate directory for the platform.

When the platform is OpenBSD, the above explanation does not apply. In this
case, the only valid key is `flags` and the value of it is passed to
`daemon_flags` described in [`rc.conf(5)`](http://man.openbsd.org/rc.conf),
where `daemon` is the name of one of the `rc.d(8)` daemon control scripts.

## `unbound_flags_default`

This variable is a dict of keys and values derived from upstream's default
configuration, and is supposed to be a constant unless absolutely necessary. By
default, the role creates a startup configuration file for each platform with
this variable, identical to default one.

When the platform is OpenBSD, the variable has a single key, `flags` and its
value is empty string.

## `unbound_config_server`

`unbound_config_server` is a list of settings in `unbound.conf(5)`. Elements
can be string, or dict. Note that `directory` and `chroot` are hard-coded, and
cannot be set in `unbound_config_server`. Use the provided role variables for
them.

When an element is a string, the string is simply added to `unbound.conf(5)`.
An example:

```yaml
unbound_config_server:
  - "hide-identity: yes"
```

Which generates:

```yaml
server:
  hide-identity: yes
```

When an element is a dict, the dict must have a mandatory key `name`. The dict
also must have either `value`, or `values` as a key.

| Key | Value | Description |
|-----|-------|-------------|
| `name` | name of setting | one of keywords listed in "Server Options" in `unbound.conf(5)` |
| `value` | single value of the `name` setting | see `unbound.conf(5)` |
| `values` | list of values of the `name` setting | use this if the `name` setting is allowed to be appear multiple times in `unbound.conf(5)` |

Here is a single-value example:

```yaml
unbound_config_server:
  - name: use-syslog
    value: "yes"
```

Which generates:

```yaml
server:
  use-syslog: yes
```

Here is a multiple-values example:

```yaml
unbound_config_server:
  - name: access-control
    values:
      - 0.0.0.0/0 refuse
      - 127.0.0.0/8 allow
```

Which generates:

```yaml
server:
  access-control: 0.0.0.0/0 refuse
  access-control: 127.0.0.0/8 allow
```

## `unbound_forward_zone`

`unbound_forward_zone` is a list of zones described in "Forward Zone Options"
in `unbound.conf(5)`.

An element is a dict of zone. The dict must have a mandatory key, `name`, whose
value is the name of the zone . Other key in the dict is a setting for the
zone, such as `forward-addr`, whose value is the value of the setting. See
"Forward Zone Options" in `unbound.conf(5)`. Value of optional settings can be
a string or a list. An example:

```yaml
unbound_forward_zone:
  - name: example.com
    forward-addr:
      - 8.8.8.8
      - 8.8.4.4
```
## `unbound_stub_zone`

`unbound_stub_zone` is same variable as `unbound_forward_zone`, but for stub
zone. See "Stub Zone Options" in `unbound.conf(5)`.

An example:

```yaml
unbound_stub_zone:
  - name: example.net
    stub-addr:
      - 8.8.8.8
      - 8.8.4.4
```

## Debian

| Variable | Default |
|----------|---------|
| `__unbound_user` | `unbound` |
| `__unbound_group` | `unbound` |
| `__unbound_conf_dir` | `/etc/unbound` |
| `__unbound_script_dir` | `/usr/bin` |
| `__unbound_directory` | `/etc/unbound` |
| `__unbound_flags_default` | `{}` |

## FreeBSD

| Variable | Default |
|----------|---------|
| `__unbound_user` | `unbound` |
| `__unbound_group` | `unbound` |
| `__unbound_conf_dir` | `/usr/local/etc/unbound` |
| `__unbound_script_dir` | `/usr/local/bin` |
| `__unbound_directory` | `/usr/local/etc/unbound` |
| `__unbound_flags_default` | `{}` |

## OpenBSD

| Variable | Default |
|----------|---------|
| `__unbound_user` | `_unbound` |
| `__unbound_group` | `_unbound` |
| `__unbound_conf_dir` | `/var/unbound/etc` |
| `__unbound_script_dir` | `/usr/local/bin` |
| `__unbound_directory` | `/var/unbound` |
| `__unbound_flags_default` | `{"flags"=>""}` |

## RedHat

| Variable | Default |
|----------|---------|
| `__unbound_user` | `unbound` |
| `__unbound_group` | `unbound` |
| `__unbound_conf_dir` | `/etc/unbound` |
| `__unbound_script_dir` | `/usr/bin` |
| `__unbound_directory` | `/etc/unbound` |
| `__unbound_flags_default` | `{"UNBOUND_OPTIONS"=>""}` |

# Dependencies

None

# Example Playbook

```yaml
- hosts: localhost
  roles:
    - ansible-role-unbound
  vars:
    debian_flags:
      DAEMON_OPTS: "-v -c {{ unbound_conf_file }}"
    freebsd_flags:
      unbound_flags: "-v -c {{ unbound_conf_file }}"
    redhat_flags:
      UNBOUND_OPTIONS: "-v -c {{ unbound_conf_file }}"
    openbsd_flags:
      flags: "-v -c {{ unbound_conf_file }}"

    unbound_flags: "{% if ansible_os_family == 'Debian' %}{{ debian_flags }}{% elif ansible_os_family == 'FreeBSD' %}{{ freebsd_flags }}{% elif ansible_os_family == 'RedHat' %}{{ redhat_flags }}{% elif ansible_os_family == 'OpenBSD' %}{{ openbsd_flags }}{% endif %}"

    unbound_config_chroot: ""
    unbound_config_server:
      - "outgoing-interface: {{ ansible_default_ipv4.address }}"
      - "do-not-query-localhost: yes"
      - "do-ip4: yes"
      - "do-ip6: no"
      - "hide-identity: yes"
      - "hide-version: yes"
      # you may use dict, too
      - name: use-syslog
        value: "yes"
      # some settings are allowed to appear multiple times, which makes
      # `unbound.conf(5)` different from YAML.
      - name: local-zone
        values:
          - 10.in-addr.arpa nodefault
          - 168.192.in-addr.arpa nodefault
      - name: access-control
        values:
          - 0.0.0.0/0 refuse
          - 127.0.0.0/8 allow
          - 10.100.1.0/24 allow
      - name: private-address
        values:
          - 10.0.0.0/8
          - 172.16.0.0/12
          - 192.168.0.0/16
          - 192.254.0.0/16
          - fc00::/7
          - fd00::/8
          - fe80::/10
      - name: private-domain
        values:
          - '"example.com"'
      # if `values` has a single value, you may use `values`, which is not
      # recommended. prefer `value` to `values` in this case.
      - name: interface
        values:
          - "{{ ansible_default_ipv4.address }}"
    # unbound in ubuntu 14.04 does not support unix socket
    unbound_config_remote_control_control_interface: "{% if (ansible_distribution == 'Ubuntu' and ansible_distribution_version | version_compare('14.04', '<=')) or (ansible_distribution == 'CentOS' and ansible_distribution_version | version_compare('7.3.1611', '<=')) %}127.0.0.1{% else %}/var/run/unbound.sock{% endif %}"
    unbound_forward_zone:
      -
        name: example.com
        forward-addr:
          - 8.8.8.8
          - 8.8.4.4
      -
        name: example.org
        forward-addr:
          - 8.8.8.8
    unbound_stub_zone:
      - name: example.net
        stub-addr:
          - 8.8.8.8
          - 8.8.4.4
      - name: foo.example
        stub-addr:
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
