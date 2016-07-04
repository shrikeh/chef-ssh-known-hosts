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
require_relative '../libraries/ssh_user_known_hosts'

# Override Load Current Resource
def load_current_resource
  @current_resource = Chef::Resource::SshUserKnownHostsEntries.new(
    @new_resource.name
  )

  # A common step is to load the current_resource instance variables with what
  # is established in the new_resource.
  # What is passed into new_resouce via our recipes, is not automatically passed
  # to our current_resource.
  # DSL converts our parameters/attrbutes to methods to get and set the instance
  # variable inside the Provider and Resource.
  @current_resource.entries(@new_resource.entries)
  @current_resource.path(@new_resource.path)
  @current_resource.append(@new_resource.append)
  @current_resource.owner(@new_resource.owner)
  @current_resource.group(@new_resource.group)
  @current_resource.mode(@new_resource.mode)
end

# Helper module for Chef
module CreateUserKnownHostEntries
  include SshUserKnownHosts

  module_function

  @regex_entry = Regexp.new('([^\s]+) ([a-z0-9-]+) ([0-9A-Za-z/+]+[=]*)')

  def create_user_known_host_entries(entries)
    fail_msg = 'Argument error not of type Array, instead got %s'
    fail printf(fail_msg, entries.class) unless entries.is_a?(Array)
    host_entries = []
    entries.each do |entry|
      host_entry = from_entry(entry)
      fail host_entry.inspect unless host_entry.is_a?(HostEntry)
      host_entries.push(host_entry)
    end
    HostEntriesCollection.new(host_entries)
  end

  def from_entry(entry)
    create_known_hosts_entry(
      entry['host'],
      entry['type'],
      entry['key']
    )
  end

  def create_known_hosts_entry(host, type, key)
    HostEntry.new(Host.from_string(host), HostKey.from_parts(key, type))
  end

  def parse_known_host_string(str)
    str.scan(@regex_entry)
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
    fail_msg = 'Argument error not of type Array, instead got %s'
    fail printf(fail_msg, new_resource.entries.inspect) unless
      new_resource
      .entries
      .is_a?(Array)
    entries =
      CreateUserKnownHostEntries
      .create_user_known_host_entries(new_resource.entries)
  end

  if new_resource.append
    if ::File.exist?(new_resource.path)
      existing_keys =
        CreateUserKnownHostEntries
        .from_string(IO.read(new_resource.path))
      entries = existing_keys.merge(entries)
    end
  end

  f = file "ssh_known_hosts-#{new_resource.name}" do
    path new_resource.path
    action :create
    backup false
    owner new_resource.owner if new_resource.owner
    group new_resource.group if new_resource.group
    mode new_resource.mode
    content "#{entries}"
  end

  msg = 'Updated %s'
  Chef::Log.info printf(msg, new_resource.path) if f.updated_by_last_action?

  f.updated_by_last_action?
end
