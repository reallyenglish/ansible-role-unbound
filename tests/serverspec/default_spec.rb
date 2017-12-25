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
default_user = "root"
default_group = "root"
flags_file = ""

case os[:family]
when "freebsd"
  conf_dir = "/usr/local/etc/unbound"
  directory = "/usr/local/etc/unbound"
  script_dir = "/usr/local/bin"
  default_group = "wheel"
  flags_file = "/etc/rc.conf.d/#{service}"
when "openbsd"
  user = "_unbound"
  group = "_unbound"
  conf_dir = "/var/unbound/etc"
  directory = "/var/unbound"
  script_dir = "/usr/local/bin"
  default_group = "wheel"
  flags_file = "/etc/rc.conf.local"
when "ubuntu"
  directory = "/etc/unbound"
  flags_file = "/etc/default/#{service}"
when "redhat"
  directory = "/etc/unbound"
  flags_file = "/etc/sysconfig/#{service}"
end
config = "#{conf_dir}/unbound.conf"

if os[:family] != "openbsd"
  describe package(package) do
    it { should be_installed }
  end
end

describe file(flags_file) do
  it { should exist }
  it { should be_file }
  it { should be_owned_by default_user }
  it { should be_grouped_into default_group }
  it { should be_mode 644 }
  case os[:family]
  when "openbsd"
    its(:content) { should match(/^unbound_flags=-v -c #{Regexp.escape(config)}$/) }
  when "redhat"
    its(:content) { should match(/^UNBOUND_OPTIONS="-v -c #{Regexp.escape(config)}"$/) }
  when "ubuntu"
    its(:content) { should match(/^DAEMON_OPTS="-v -c #{Regexp.escape(config)}"$/) }
  when "freebsd"
    its(:content) { should match(/^unbound_flags="-v -c #{Regexp.escape(config)}"$/) }
  end
end

describe user(user) do
  it { should exist }
  it { should belong_to_primary_group group }
end

describe file(config) do
  it { should exist }
  it { should be_file }
  it { should be_mode 644 }
  it { should be_owned_by default_user }
  it { should be_grouped_into default_group }
  # server
  its(:content_as_yaml) { should include("server" => include("interface" => "10.0.2.15")) }
  its(:content_as_yaml) { should include("server" => include("directory" => directory)) }
  its(:content_as_yaml) { should include("server" => include("chroot" => "")) }
  its(:content_as_yaml) { should include("server" => include("outgoing-interface" => "10.0.2.15")) }
  its(:content_as_yaml) { should include("server" => include("do-not-query-localhost" => true)) }
  its(:content_as_yaml) { should include("server" => include("do-ip4" => true)) }
  its(:content_as_yaml) { should include("server" => include("do-ip6" => false)) }
  its(:content_as_yaml) { should include("server" => include("hide-identity" => true)) }
  its(:content_as_yaml) { should include("server" => include("hide-version" => true)) }
  its(:content_as_yaml) { should include("server" => include("use-syslog" => true)) }
  its(:content_as_yaml) { should_not include("server" => "chroot") }
  its(:content) { should match(/access-control: #{ Regexp.escape('0.0.0.0/0 refuse')    }/) }
  its(:content) { should match(/access-control: #{ Regexp.escape('127.0.0.0/8 allow')   }/) }
  its(:content) { should match(/access-control: #{ Regexp.escape('10.100.1.0/24 allow') }/) }
  its(:content) { should match(/local-zone:\s+10\.in-addr\.arpa nodefault\n/) }
  its(:content) { should match(/local-zone:\s+168\.192\.in-addr\.arpa nodefault\n/) }
  %w[10.0.0.0/8 172.16.0.0/12 192.168.0.0/16 192.254.0.0/16 fc00::/7 fd00::/8 fe80::/10].each do |addr|
    its(:content) { should match(/private-address: #{ Regexp.escape(addr) }/) }
  end
  its(:content) { should match(/private-domain: "example\.com"/) }

  # remote-control
  its(:content_as_yaml) { should include("remote-control" => include("control-enable" => true)) }
  if (os[:family] == "ubuntu" && os[:release].to_f <= 14.04) || (os[:family] == "redhat" && os[:release].to_f <= 7.4)
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
  if (os[:family] == "ubuntu" && os[:release].to_f <= 14.04) || (os[:family] == "redhat" && os[:release].to_f <= 7.4)
    its(:content_as_yaml) { should include("remote-control" => include("control-interface" => "127.0.0.1")) }
  else
    its(:content_as_yaml) { should include("remote-control" => include("control-interface" => "/var/run/unbound.sock")) }
  end

  # forward-zone
  its(:content) { should match(/^forward-zone:\n\s+name: "example\.com"\n\s+forward-addr: "8\.8\.8\.8"\n\s+forward-addr:\s+"8\.8\.4\.4"\n/) }
  its(:content) { should match(/^forward-zone:\n\s+name: "example\.org"\n\s+forward-addr: "8\.8\.8\.8"\n/) }

  # stub-zone
  its(:content) { should match(/^stub-zone:\n\s+name: "example\.net"\n\s+stub-addr: "8\.8\.8\.8"\n\s+stub-addr:\s+"8\.8\.4\.4"\n/) }
  its(:content) { should match(/^stub-zone:\n\s+name: "foo\.example"\n\s+stub-addr: "8\.8\.8\.8"\n/) }
end

describe service(service) do
  it { should be_running }
  it { should be_enabled }
end

describe process("unbound") do
  its(:user) do
    pending "due to a bug in serverspec, this does not work on OpenBSD" if os[:family] == "openbsd"
    should eq user
  end
  its(:args) do
    pending "due to a bug in serverspec, this does not work on OpenBSD" if os[:family] == "openbsd"
    should match(/-v -c #{Regexp.escape(config)}/)
  end
end
case os[:family]
when /bsd$/
  # workaround for the above issue
  describe command("ps -ax -o user,args") do
    its(:exit_status) { should eq 0 }
    its(:stderr) { should eq "" }
    its(:stdout) { should match(/^#{user}\s+(?:#{Regexp.escape("/usr/local/sbin/")})?#{Regexp.escape("unbound -v -c #{config}")}$/) }
  end
end

ports.each do |p|
  describe port(p) do
    it { should be_listening }
  end
end

describe file(conf_dir) do
  it { should exist }
  it { should be_directory }
  it { should be_owned_by default_user }
  it { should be_grouped_into group }
  it { should be_mode 775 }
end

keys.each do |key|
  describe file "#{conf_dir}/#{key}" do
    it { should be_file }
    it { should be_owned_by default_user }
    it { should be_grouped_into group }
    it { should be_mode 640 }
  end
end

unless script_dir =~ %r{/usr/(?:local/)?s?bin$}
  describe file(script_dir) do
    it { should exist }
    it { should be_directory }
    it { should be_owned_by default_user }
    it { should be_grouped_into default_group }
    it { should be_mode 755 }
  end
end

describe file("#{script_dir}/ansible-unbound-checkconf") do
  it { should exist }
  it { should be_file }
  it { should be_owned_by default_user }
  it { should be_grouped_into default_group }
  it { should be_mode 755 }
end
