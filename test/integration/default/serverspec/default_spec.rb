require 'spec_helper'

describe file('/tmp/foo') do
  # Serverspec examples can be found at
  # http://serverspec.org/resource_types.html
  it { should be_file }
  its(:content) { should match(/^github.com/)}
end
