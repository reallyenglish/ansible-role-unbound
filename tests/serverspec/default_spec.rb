require 'spec_helper'

package = 'unbound'
service = 'unbound'
config  = '/etc/unbound/unbound.conf'
user    = 'unbound'
group   = 'unbound'
ports   = [ 53 ]

case os[:family]
when 'freebsd'
  config = '/usr/local/etc/unbound/unbound.conf'
when 'openbsd'
  config = '/var/unbound/etc/unbound.conf'
end

case os[:family]
when 'openbsd'
else
  describe package(package) do
    it { should be_installed }
  end 
end

describe file(config) do
  it { should be_file }
  its(:content) { should match /interface: / } # XXX
  its(:content) { should match /outgoing-interface: / } # XXX
  its(:content) { should match /do-not-query-localhost: yes/ }
  its(:content) { should match /do-ip4: yes/ }
  its(:content) { should match /do-ip6: no/ }
  its(:content) { should match /access-control: #{ Regexp.escape('0.0.0.0/0 refuse')    }/ }
  its(:content) { should match /access-control: #{ Regexp.escape('127.0.0.0/8 allow')   }/ }
  its(:content) { should match /access-control: #{ Regexp.escape('10.100.1.0/24 allow') }/ }
  its(:content) { should match /hide-identity: yes/ }
  its(:content) { should match /hide-version: yes/ }
  its(:content) { should match /use-syslog: yes/ }
  %w[ 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16 192.254.0.0/16 fd00::/8 fe80::/10 ].each do |addr|
    its(:content) { should match /private-address: #{ Regexp.escape(addr) }/ }
  end
  its(:content) { should match /private-domain: "example\.com"/ }
  its(:content) { should match /control-enable: yes/ }
  puts os[:family]
  puts os[:release].to_f

  if (os[:family] == 'ubuntu' && os[:release].to_f <= 14.04) or (os[:family] == 'redhat' && os[:release].to_f <= 7.2)
    # control-use-cert: is not suppoted
  else
    its(:content) { should match /control-use-cert: no/ }
  end
  if (os[:family] == 'ubuntu' && os[:release].to_f <= 14.04) or (os[:family] == 'redhat' && os[:release].to_f <= 7.2)
    its(:content) { should match /control-interface: #{ Regexp.escape('127.0.0.1') }/ }
  else
    its(:content) { should match /control-interface: #{ Regexp.escape('/var/run/unbound.sock') }/ }
  end
  its(:content) { should match /^forward-zone:\n\s+name: "example\.com"\n\s+forward-addr: 8\.8\.8\.8/ }
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
