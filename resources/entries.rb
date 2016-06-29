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

def initialize(*args)
  super
  @action = :create
end

require_relative '../libraries/ssh_known_hosts'

module CreateUserKnownHostEntries
  include SshKnownHosts
  extend self

  def create_user_known_host_entries(entries)
    raise "Argument error not of type Array, instead #{entries.class}" unless entries.kind_of?(Array)
    host_entries = []
    entries.each do |entry|
      host = Host.fromString(entry['host'])
      key = HostKey.fromParts(entry['key'], entry['type'])
      host_entries.push(HostEntry.new(host, key))
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

  file "ssh_known_hosts-#{new_resource.name}" do
    path    new_resource.path
    action  :create
    backup  false
    content "#{entries}"
  end
end
