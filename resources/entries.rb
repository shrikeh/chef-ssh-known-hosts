#!/usr/bin/env ruby
#
# Author:: Barney Hanlon (<shrikeh@gmail.com>)
# Resource:: entry
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

resource_name 'ssh_user_known_hosts_entries'

actions :create
default_action :create

property :entries, kind_of: Array
property :path, kind_of: String, name_property:  true
property :append, kind_of: [TrueClass, FalseClass], default: true
property :owner, kind_of: [String, Integer]
property :group, kind_of: [String, Integer]
property :mode, kind_of: [String, Integer], default: '0644'

def initialize(*args)
  super
  @action = :create
end

require_relative '../libraries/ssh_known_hosts'

module CreateUserKnownHostEntries
  include SshKnownHosts
  extend self

  @regexEntry = Regexp.new('([^\s]+) ([a-z0-9-]+) ([0-9A-Za-z/+]+[=]+)')

  def create_user_known_host_entries(entries)
    raise "Argument error not of type Array, instead #{entries.class}" unless entries.kind_of?(Array)
    host_entries = []
    entries.each do |entry|
      host_entry = create_known_hosts_entry(entry['host'], entry['type'], entry['key'])
      raise host_entry.inspect unless host_entry.kind_of?(HostEntry)
      host_entries.push(host_entry)
    end
    HostEntriesCollection.new(host_entries)
  end

  def create_known_hosts_entry(host, type, key)
    HostEntry.new(Host.fromString(host), HostKey.fromParts(key, type))
  end

  def parse_known_host_string(str)
      str.scan(@regexEntry)
  end

  def from_string(str)
    host_entries = []
    # iterate through the file line by line
    str.lines.each do |line|
      parse_known_host_string(line).each do |host, type, key|
        entry = create_known_hosts_entry(host, type, key)
        host_entries.push(entry)
      end
    end
    HostEntriesCollection.new(host_entries)
  end
end

use_inline_resources if defined?(use_inline_resources)

def whyrun_supported?
  true
end

action :create do

  if new_resource.entries
     raise "Argument error not of type Array, instead #{new_resource.entries.inspect}" unless new_resource.entries.kind_of?(Array)
     entries = CreateUserKnownHostEntries.create_user_known_host_entries(new_resource.entries)
  end

  if new_resource.append
    if ::File.exists?(new_resource.path)
      existing_keys = CreateUserKnownHostEntries.from_string(IO.read(new_resource.path))
      entries = existing_keys.merge(entries)
    end
  end

  file "ssh_known_hosts-#{new_resource.name}" do
    path    new_resource.path
    action  :create
    backup  false
    owner   new_resource.owner if new_resource.owner
    group   new_resource.group if new_resource.group
    mode    new_resource.mode
    content "#{entries}"
  end
end
