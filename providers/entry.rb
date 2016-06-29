#!/usr/bin/env ruby
#
# Author:: Barney Hanlon (<shrikeh@gmail.com>)
# Resource:: host
#
# Copyright 2015, Barney Hanlon
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
require_relative '../libraries/ssh_known_hosts'

module CreateUserKnownHostEntry
  include SshKnownHosts
  extend self

  def create_user_known_host_entry(res)
    key = HostKey.fromParts(res.key, res.type)
    host = Host.fromString(res.host)
    HostEntry.new(host, key)
  end
end

use_inline_resources if defined?(use_inline_resources)

def whyrun_supported?
  true
end

action :create do

  key = CreateUserKnownHostEntry.create_user_known_host_entry(new_resource).to_s

  comment = key.to_s.split("\n").first || ''

  if key_exists?(key, comment)
    Chef::Log.debug printf('Known hosts key for %s already exists - skipping', new_resource.name)
  else
    new_keys = (keys + [key]).uniq.sort
    file "ssh_known_hosts-#{new_resource.name}" do
      path    new_resource.path
      action  :create
      backup  false
      content "#{new_keys.join("\n")}"
    end
  end
end

def create_host_entry

end

private

def keys
  unless @keys
    if key_file_exists?
      lines = ::File.readlines(new_resource.path)
      @keys = lines.map(&:chomp).reject(&:empty?)
    else
      @keys = []
    end
  end
  @keys
end

def key_file_exists?
  ::File.exist?(new_resource.path)
end

def key_exists?(key, comment)
  keys.any? do |line|
    line.match(/#{Regexp.escape(comment)}|#{Regexp.escape(key)}/)
  end
end
