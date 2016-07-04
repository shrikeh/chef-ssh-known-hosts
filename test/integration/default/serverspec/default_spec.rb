require 'spec_helper'

describe file('/tmp/foo') do
  # Serverspec examples can be found at
  # http://serverspec.org/resource_types.html
  it { should be_file }
  key = 'github.com,192.30.252.128,192.30.252.129 ssh-rsa AAAAB'

  regex = Regexp.new(Regexp.escape(key))

  its(:content) { should match regex }
end
