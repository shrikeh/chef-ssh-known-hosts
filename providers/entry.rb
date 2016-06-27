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

module CreateUserKnownHosts
  include SshKnownHosts
  extend self

  def create_host(res)
    return Host.fromString(res.host)
  end

  def create_user_known_host_entry(res)
    key = create_user_known_host_key(res)
    host = create_host(res)
    HostEntry.new(host, key)
  end

  def create_user_known_host_key(res)
    if res.key
      if res.key_type == 'rsa' || res.key_type == 'dsa'
        key_type = "ssh-#{res.key_type}"
      else
        key_type = res.key_type
      end
    else
      #key = `ssh-keyscan -t #{node['ssh_known_hosts']['key_type']} -p #{new_resource.port} #{new_resource.host}`
    end
      HostKey.new(res.key, key_type)
    end
end

use_inline_resources if defined?(use_inline_resources)

def whyrun_supported?
  true
end

action :create do

  key = CreateUserKnownHosts.create_user_known_host_entry(new_resource)

  comment = key.to_s.split("\n").first || ''

  if key_exists?(key, comment)
    Chef::Log.debug "Known hosts key for #{new_resource.name} already exists - skipping"
  else
    new_keys = (keys + [key]).uniq.sort
    file "ssh_known_hosts-#{new_resource.name}" do
      path    new_resource.path
      action  :create
      backup  false
      content "#{new_keys.join($INPUT_RECORD_SEPARATOR)}#{$INPUT_RECORD_SEPARATOR}"
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
