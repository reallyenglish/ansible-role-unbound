## Release 2.1.0

* 436a3e1 [feature][bugfix] Support unbound 1.6 and OpenBSD 6.1 (#36), closes #34

## Release 2.0.0

* fccbfc6 [bugfix] use reallyenglish.devfsrules, remove chroot hacks (#32)
* c8e56e7 [backward incompatible] support arbitrary settings in unbound.conf(5) (#31)
* 851dbaf QA (#24)
* e57f2f8 Remove a logic to take different actions depending on OS version  (#18)
* faaef16 Connect the integration test to build (#17)
* `unbound_config_directory` was renamed. Use `unbound_directory`
* support stub-zone

Since the last release, `unbound_config_server` supports arbitrary
configurations. You need to modify `unbound_config_server` before upgrading.
See [`unbound_config_server`](https://github.com/reallyenglish/ansible-role-unbound#unbound_config_server)
for details.

## Release 1.0.0

* intial release
