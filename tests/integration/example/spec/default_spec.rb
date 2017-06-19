require "spec_helper"

class ServiceNotReady < StandardError
end

sleep 10 if ENV["JENKINS_HOME"]

context "after provisioning finished" do
  describe server(:client1) do
    it "should be able to resolve google.com" do
      result = current_server.ssh_exec("drill -o RD example.com @#{server(:resolver1).server.address} a")
      expect(result).to match(/QUERY: 1, ANSWER: [1-9], AUTHORITY: \d+, ADDITIONAL: \d+/)
      expect(result).to match(/^example\.com\.\s+\d+\s+IN\s+A\s+[0-9.]+$/)
    end
  end
end
