require_relative "default_spec.rb"

describe port(853) do
  it { should be_listening }
end

describe command("echo | openssl s_client -connect 127.0.0.1:853 -showcerts") do
  its(:stdout) { should match(/#{Regexp.escape("issuer=/C=AU/ST=Some-State/O=Internet Widgits Pty Ltd/CN=foo.example.org")}/) }
  its(:stderr) { should match(/verify error:num=18:self signed certificate/) }
  its(:exit_status) { should eq 0 }
end
