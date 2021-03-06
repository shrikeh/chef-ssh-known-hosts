#!/usr/bin/env ruby

Given(/^the user account is "([^"]*)"$/) do |user|
  @ssh_user = user
  `sudo useradd -p '' #{@ssh_user}`
end

Given(/^their known hosts file is "([^"]*)"$/) do |host_file|
  @host_file = host_file
  `mkdir -p $(dirname #{@host_file})`
  `touch #{@host_file}`
end

Given(/^there are existing entries$/) do
  existing_entries = <<-EOT.gsub(/\n/, '')
github.com,192.30.252.128 ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9
IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGE
YsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8x
hHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RK
rTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUF
FAaQ==
EOT
  cmd = "echo '#{existing_entries}' > #{@host_file}"
  `#{cmd}`
end

When(/^Chef runs and the node has new known host entries$/) do
  @chef_run = `cd /tmp/kitchen/ && sudo chef-solo -j dna.json -c solo.rb`
  @success = $CHILD_STATUS.to_i
end

Then(/^new entries are appended and the existing entries are preserved$/) do
  hosts = ['github.com', '192.30.252.128', '192.30.252.129']

  hosts.each do | host |
    @exists = `ssh-keygen -F #{host} -f #{@host_file}`
    regexp = Regexp.new(Regexp.escape(host))
    expect("#{@exists}").to match(regexp)
  end
end
