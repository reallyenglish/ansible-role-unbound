require "spec_helper"

package = "unbound"
service = "unbound"
user    = "unbound"
group   = "unbound"
ports   = [53]
conf_dir = "/etc/unbound"
directory = ""
keys = %w[unbound_server.key unbound_server.pem unbound_control.key unbound_control.pem]
script_dir = "/usr/bin"
chroot_dir = ""
unbound_freebsd_chroot_devfs_ruleset_number = 100

case os[:family]
when "freebsd"
  conf_dir = "/usr/local/etc/unbound"
  directory = "/usr/local/etc/unbound"
  script_dir = "/usr/local/bin"
  chroot_dir = "/usr/local/etc/unbound"
when "openbsd"
  user = "_unbound"
  group = "_unbound"
  conf_dir = "/var/unbound/etc"
  directory = "/var/unbound"
  script_dir = "/usr/local/bin"
  chroot_dir = "/var/unbound"
when "ubuntu"
  directory = "/etc/unbound"
when "redhat"
  directory = "/etc/unbound"
end
config = "#{conf_dir}/unbound.conf"

if os[:family] != "openbsd"
  describe package(package) do
    it { should be_installed }
  end
end

describe user(user) do
  it { should exist }
  it { should belong_to_primary_group group }
end

case os[:family]
when "freebsd"
  describe file("#{chroot_dir}/dev") do
    it { should be_directory }
    it { should be_mounted }
  end

  describe command("devfs -m #{chroot_dir}/dev rule show") do
    its(:exit_status) { should eq 0 }
    its(:stdout) { should match(/^100 include 1$/) }
    its(:stdout) { should match(/^200 include 2$/) }
    its(:stdout) { should match(/^300 path random unhide$/) }
    its(:stdout) { should match(/^400 path urandom unhide$/) }
    its(:stderr) { should eq "" }
  end

  describe command("devfs rule -s #{unbound_freebsd_chroot_devfs_ruleset_number} show") do
    its(:exit_status) { should eq 0 }
    its(:stdout) { should match(/^100 include 1$/) }
    its(:stdout) { should match(/^200 include 2$/) }
    its(:stdout) { should match(/^300 path random unhide$/) }
    its(:stdout) { should match(/^400 path urandom unhide$/) }
    its(:stderr) { should eq "" }
  end

  describe command("devfs rule showsets") do
    its(:exit_status) { should eq 0 }
    its(:stdout) { should match(/^#{ Regexp.escape(unbound_freebsd_chroot_devfs_ruleset_number.to_s) }$/) }
    its(:stderr) { should eq "" }
  end

  devices = %w[
    random
    urandom
  ]
  devices.each do |dev|
    describe file("#{chroot_dir}/dev/#{dev}") do
      it { should be_character_device }
    end
  end

  describe file("#{chroot_dir}/dev/console") do
    it { should_not exist }
  end

when "openbsd"

  describe file("/etc/fstab") do
    its(:content) { should match(/^swap #{Regexp.escape("/var/unbound/dev")} mfs rw,nosuid,-s=256k 0 0/) }
  end

  describe command("mount") do
    its(:exit_status) { should eq 0 }
    its(:stdout) { should match(/^mfs:\d+ on #{Regexp.escape("/var/unbound/dev")} type mfs \(asynchronous, local, nosuid, size=512 512-blocks\)/) }
  end

  describe file("#{chroot_dir}/dev") do
    it { should be_mounted }
  end

  devices = %w[
    random
    null
    zero
    stdin
    stdout
    stderr
  ]
  devices.each do |dev|
    describe file("#{chroot_dir}/dev/#{dev}") do
      it { should be_character_device }
    end
  end

  describe file("/usr/local/bin/mk_chroot") do
    it { should be_file }
    it { should be_executable }
  end

  describe file("/etc/rc.local") do
    its(:content) { should match(Regexp.escape("[ -x /usr/local/bin/mk_chroot ] && /usr/local/bin/mk_chroot /var/unbound")) }
  end

end

describe file(config) do
  it { should be_file }

  # server
  its(:content_as_yaml) { should include("server" => include("directory" => directory)) }
  its(:content_as_yaml) { should include("server" => include("chroot" => chroot_dir)) }
  its(:content_as_yaml) { should include("server" => include("outgoing-interface" => "10.0.2.15")) }
  its(:content_as_yaml) { should include("server" => include("do-not-query-localhost" => true)) }
  its(:content) { should match(/access-control: #{ Regexp.escape('0.0.0.0/0 refuse')    }/) }
  its(:content) { should match(/access-control: #{ Regexp.escape('127.0.0.0/8 allow')   }/) }
  its(:content) { should match(/access-control: #{ Regexp.escape('10.100.1.0/24 allow') }/) }

  # remote-control
  its(:content_as_yaml) { should include("remote-control" => include("control-enable" => true)) }
  if (os[:family] == "ubuntu" && os[:release].to_f <= 14.04) || (os[:family] == "redhat" && os[:release].to_f <= 7.2)
    # control-use-cert: is not suppoted
  else
    its(:content_as_yaml) { should include("remote-control" => include("control-use-cert" => false)) }
    keys.each do |key|
      name, ext = key.split(".")
      type = name.gsub("unbound_", "")
      ext.gsub!("pem", "cert")
      its(:content_as_yaml) { should include("remote-control" => include("#{type}-#{ext}-file" => "#{conf_dir}/#{key}")) }
    end
  end
  if (os[:family] == "ubuntu" && os[:release].to_f <= 14.04) || (os[:family] == "redhat" && os[:release].to_f <= 7.2)
    its(:content_as_yaml) { should include("remote-control" => include("control-interface" => "127.0.0.1")) }
  else
    its(:content_as_yaml) { should include("remote-control" => include("control-interface" => "/var/run/unbound.sock")) }
  end
end

describe service(service) do
  it { should be_running }
  it { should be_enabled }
end

ports.each do |p|
  describe port(p) do
    it { should be_listening }
  end
end

describe file(conf_dir) do
  it { should be_directory }
  it { should be_owned_by "root" }
  it { should be_grouped_into group }
  it { should be_mode 775 }
end

keys.each do |key|
  describe file "#{conf_dir}/#{key}" do
    it { should be_file }
    it { should be_owned_by "root" }
    it { should be_grouped_into group }
    it { should be_mode 640 }
  end
end

describe file(script_dir) do
  it { should be_directory }
end

describe file("#{script_dir}/ansible-unbound-checkconf") do
  it { should be_file }
  it { should be_mode 755 }
end

case os[:family]
when "freebsd"
  describe command("drill example.com @127.0.0.1") do
    its(:exit_status) { should eq 0 }
    its(:stdout) { should match(/;; flags: qr rd ra ; QUERY: 1, ANSWER: [1-9]+, AUTHORITY: \d+, ADDITIONAL: \d+/) }
    its(:stdout) { should match(/;; ANSWER SECTION:\n#{ Regexp.escape('example.com.') }\s+\d+\s+IN\s+A\s+\d.*/) }
    its(:stderr) { should eq "" }
  end
when "openbsd"
  describe command("dig example.com @127.0.0.1") do
    its(:exit_status) { should eq 0 }
    its(:stdout) { should match(/;; flags: qr rd ra; QUERY: 1, ANSWER: [1-9]+, AUTHORITY: \d+, ADDITIONAL: \d+/) }
    its(:stdout) { should match(/;; ANSWER SECTION:\n#{ Regexp.escape('example.com.') }\s+\d+\s+IN\s+A\s+\d.*/) }
    its(:stderr) { should eq "" }
  end
end
