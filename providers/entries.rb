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
module KnownHostFile
  module Parse
    module_function
    include SshUserKnownHosts

    @regex_entry = Regexp.new('([^\s]+) ([a-z0-9-]+) ([0-9A-Za-z/+]+[=]*)')

    def parse_known_host_string(str)
      str.scan(@regex_entry).map { | part |
        {
          'host' => part[0],
          'type' => part[1],
          'key'  => part[2]
        }
      }
    end

    def check_existing_entry(entry, path)
      existing_hosts = []
      entry.hosts.each do | host |
        if !keygen_check_host(host, path)
          existing_hosts.push(host)
        end
      end
      existing_hosts
    end

    def check_existing_entries(entries, path)
      filtered_entries = []
      entries.each do |entry|
        check_existing_entry(entry, path).each do |host|

        end
        filtered_entries.push(entry)
      end
      HostEntriesCollection.new(filtered_entries)
    end

    def keygen_check_host(host, path)
      output = `ssh-keygen -F #{host} -f #{path}`.split("\n")
      output[1] unless output.empty?
    end

    # def compare_host(host, path)
    #   exists = keygen_check_host(host, path)
    #   parse_known_host_string(exists).each do |match|
    #     if match['host'] == host
    #
    #     end
    #   end unless exists.nil?
    # end

    def filter_existing_entries(entries, path)
      filtered_entries = check_existing_entries(entries, path)
      entries_from_string(IO.read(path)).merge(filtered_entries)
    end

    def entries_from_string(str)
      host_entries = []
      # iterate through the file line by line
      str.lines.each do |line|
        parse_known_host_string(line).each do |parts|
          host_entries.push(
            Create.from_parts(parts)
          )
        end
      end

      HostEntriesCollection.new(host_entries)
    end
  end

  module Create
    module_function
    include SshUserKnownHosts

    def create_user_known_host_entries(entries)
      fail_msg = 'Argument error not of type Array, instead got %s'
      fail(
        ArgumentError,
        printf(fail_msg, entries.class),
        caller
      ) unless entries.is_a?(Array)

      host_entries = []
      entries.each do |entry|
        host_entry = from_parts(entry)
        fail(
          ArgumentError,
          "#{host_entry.inspect}",
          caller
        ) unless host_entry.is_a?(HostEntry)
        host_entries.push(host_entry)
      end
      HostEntriesCollection.new(host_entries)
    end

    def from_parts(parts)
      fail(
        ArgumentError,
        parts.inspect,
        caller
      ) unless parts.is_a?(Hash)
      create_known_hosts_entry(
        parts['host'],
        parts['type'],
        parts['key']
      )
    end

    def create_known_hosts_entry(host, type, key)
      fail(
        ArgumentError,
        type.inspect,
        caller
      ) unless type
      HostEntry.new(Host.from_string(host), HostKey.from_parts(key, type))
    end
  end
end

use_inline_resources if defined?(use_inline_resources)

def whyrun_supported?
  true
end

action :create do

  Chef::Log.debug "Create file #{new_resource.path} if missing"
  f = file "#{new_resource.name}-create" do
    path new_resource.path
    action :nothing
    backup false
    owner new_resource.owner if new_resource.owner
    group new_resource.group if new_resource.group
    mode new_resource.mode
  end

  fail_msg = 'entries not of type Array, instead got %s'
  fail(
    ArgumentError,
    printf(fail_msg, new_resource.entries.inspect),
    caller
  ) unless new_resource.entries.is_a?(Array)

  Chef::Log.debug "Read existing entries from #{new_resource.path}"
  ruby_block "#{new_resource.name}-entries" do
    block do
      entries = KnownHostFile::Create
        .create_user_known_host_entries(new_resource.entries)
      if new_resource.append
        entries = KnownHostFile::Parse
          .filter_existing_entries(entries, new_resource.path)
      end

      f = file "#{new_resource.name}-update" do
        path new_resource.path
        action :create
        content "#{entries}"
        backup false
        owner new_resource.owner if new_resource.owner
        group new_resource.group if new_resource.group
        mode new_resource.mode
      end
    end
    action :run
    notifies(
      :create_if_missing,
      "file[#{new_resource.name}-create]",
      :before
    )
  end

  msg = 'Updated %s'
  Chef::Log.info f.inspect if f.updated_by_last_action?
  Chef::Log.info printf(msg, new_resource.path) if f.updated_by_last_action?
  f.updated_by_last_action?
end
