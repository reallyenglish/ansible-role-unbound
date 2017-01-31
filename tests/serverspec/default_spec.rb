require 'spec_helper'

package = 'unbound'
service = 'unbound'
config  = '/etc/unbound/unbound.conf'
user    = 'unbound'
group   = 'unbound'
ports   = [ 53 ]
conf_dir = '/etc/unbound'
directory = ''
chroot  = ''
keys    = %w[ unbound_server.key unbound_server.pem unbound_control.key unbound_control.pem ]
script_dir = '/usr/bin'

case os[:family]
when 'freebsd'
  conf_dir = '/usr/local/etc/unbound'
  directory = '/usr/local/etc/unbound'
  script_dir = '/usr/local/bin'
when 'openbsd'
  user = '_unbound'
  group = '_unbound'
  conf_dir = '/var/unbound/etc'
  directory = '/var/unbound'
  script_dir = '/usr/local/bin'
when 'ubuntu'
  directory = '/etc/unbound'
when 'redhat'
  directory = '/etc/unbound'
end
config = "#{ conf_dir }/unbound.conf"

case os[:family]
when 'openbsd'
else
  describe package(package) do
    it { should be_installed }
  end 
end

describe file(config) do
  it { should be_file }

  # server
  its(:content_as_yaml) { should include('server' => include('interface' => '10.0.2.15')) }
  its(:content_as_yaml) { should include('server' => include('directory' => directory)) }
  its(:content_as_yaml) { should include('server' => include('chroot' => '')) }
  its(:content_as_yaml) { should include('server' => include('outgoing-interface' => '10.0.2.15')) }
  its(:content_as_yaml) { should include('server' => include('do-not-query-localhost' => true)) }
  its(:content_as_yaml) { should include('server' => include('do-ip4' => true)) }
  its(:content_as_yaml) { should include('server' => include('do-ip6' => false)) }
  its(:content_as_yaml) { should include('server' => include('hide-identity' => true)) }
  its(:content_as_yaml) { should include('server' => include('hide-version' => true)) }
  its(:content_as_yaml) { should include('server' => include('use-syslog' => true)) }
  its(:content) { should match /access-control: #{ Regexp.escape('0.0.0.0/0 refuse')    }/ }
  its(:content) { should match /access-control: #{ Regexp.escape('127.0.0.0/8 allow')   }/ }
  its(:content) { should match /access-control: #{ Regexp.escape('10.100.1.0/24 allow') }/ }
  %w[ 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16 192.254.0.0/16 fd00::/8 fe80::/10 ].each do |addr|
    its(:content) { should match /private-address: #{ Regexp.escape(addr) }/ }
  end
  its(:content) { should match /private-domain: "example\.com"/ }

  # remote-control
  its(:content_as_yaml) { should include('remote-control' => include('control-enable' => true)) }
  if (os[:family] == 'ubuntu' && os[:release].to_f <= 14.04) or (os[:family] == 'redhat' && os[:release].to_f <= 7.3)
    # control-use-cert: is not suppoted
  else
    its(:content_as_yaml) { should include('remote-control' => include('control-use-cert' => false)) }
    keys.each do |key|
      name, ext = key.split('.')
      type = name.gsub('unbound_', '')
      ext.gsub!('pem', 'cert')
      its(:content_as_yaml) { should include('remote-control' => include("#{ type }-#{ ext }-file" => "#{ conf_dir }/#{ key }")) }
    end
  end
  if (os[:family] == 'ubuntu' && os[:release].to_f <= 14.04) or (os[:family] == 'redhat' && os[:release].to_f <= 7.3)
    its(:content_as_yaml) { should include('remote-control' => include('control-interface' => '127.0.0.1')) }
  else
    its(:content_as_yaml) { should include('remote-control' => include('control-interface' => '/var/run/unbound.sock')) }
  end

  # forward-zone
  its(:content) { should match /^forward-zone:\n\s+name: "example\.com"\n\s+forward-addr: 8\.8\.8\.8/ }
  its(:content) { should match /^forward-zone:\n\s+name: "example\.org"\n\s+forward-addr: 8\.8\.8\.8/ }

  # stub-zone
  its(:content) { should match /^stub-zone:\n\s+name: "example\.net"\n\s+stub-addr: 8\.8\.8\.8/ }
  its(:content) { should match /^stub-zone:\n\s+name: "foo\.example"\n\s+stub-addr: 8\.8\.8\.8/ }

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
  it { should be_owned_by 'root' }
  it { should be_grouped_into group }
  it { should be_mode 775 }
end

keys.each do |key|
  describe file "#{ conf_dir }/#{ key }" do
    it { should be_file }
    it { should be_owned_by 'root' }
    it { should be_grouped_into group }
    it { should be_mode 640 }
  end
end

describe file(script_dir) do
  it { should be_directory }
end

describe file("#{ script_dir }/ansible-unbound-checkconf") do
  it { should be_file }
  it { should be_mode 755 }
end
