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
  existing_entries = <<-EOT
github.com,192.30.252.128 ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ==
EOT
  cmd = "echo '#{existing_entries}' > #{@host_file}"
  `#{cmd}`
end

When(/^Chef runs and the node has new known host entries$/) do
  @chef_run = `cd /tmp/kitchen/ && sudo chef-solo -j dna.json -c solo.rb`
  @success = $?.to_i
end

Then(/^new entries are appended and the existing entries are preserved$/) do
  host_entries = `cat #{@host_file}`
  ::STDOUT.puts host_entries.class
  key = 'github.com,192.30.252.128,192.30.252.129 ssh-rsa'
  github_key_host_type = Regexp.escape(key)
  regexp = Regexp.new("#{github_key_host_type} .*")

  expect("#{host_entries}").to match(regexp)
end
