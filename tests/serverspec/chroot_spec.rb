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
chroot_dir = ''

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
  chroot_dir = '/var/unbound'
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

case os[:family]
when 'openbsd'
  describe file("#{ chroot_dir }/dev") do
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
    describe file("#{ chroot_dir }/dev/#{ dev }") do
      it { should be_character_device }
    end
  end

  describe file('/usr/local/bin/mk_chroot') do
    it { should be_file }
    it { should be_executable }
  end

  describe file('/etc/rc.local') do
    its(:content) { should match(Regexp.escape('[ -x /usr/local/bin/mk_chroot ] && /usr/local/bin/mk_chroot /var/unbound')) }
  end
end

describe file(config) do

  it { should be_file }

  # server
  its(:content_as_yaml) { should include('server' => include('directory' => directory)) }
  its(:content_as_yaml) { should include('server' => include('chroot' => chroot_dir)) }
  its(:content_as_yaml) { should include('server' => include('outgoing-interface' => '10.0.2.15')) }
  its(:content_as_yaml) { should include('server' => include('do-not-query-localhost' => true)) }
  its(:content) { should match /access-control: #{ Regexp.escape('0.0.0.0/0 refuse')    }/ }
  its(:content) { should match /access-control: #{ Regexp.escape('127.0.0.0/8 allow')   }/ }
  its(:content) { should match /access-control: #{ Regexp.escape('10.100.1.0/24 allow') }/ }

  # remote-control
  its(:content_as_yaml) { should include('remote-control' => include('control-enable' => true)) }
  if (os[:family] == 'ubuntu' && os[:release].to_f <= 14.04) or (os[:family] == 'redhat' && os[:release].to_f <= 7.2)
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
  if (os[:family] == 'ubuntu' && os[:release].to_f <= 14.04) or (os[:family] == 'redhat' && os[:release].to_f <= 7.2)
    its(:content_as_yaml) { should include('remote-control' => include('control-interface' => '127.0.0.1')) }
  else
    its(:content_as_yaml) { should include('remote-control' => include('control-interface' => '/var/run/unbound.sock')) }
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
