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
#require_relative '../libraries/known_host_file'

# Override Load Current Resource
def load_current_resource
  @current_resource = Chef::Resource::SshUserKnownHosts.new(
    @new_resource.name
  )
  # A common step is to load the current_resource instance variables with what
  # is established in the new_resource.
  # What is passed into new_resource via our recipes, is not automatically passed
  # to our current_resource.
  # DSL converts our parameters/attrbutes to methods to get and set the instance
  # variable inside the Provider and Resource.
  @current_resource.entries(@new_resource.entries)
  @current_resource.path(@new_resource.path)
  @current_resource.hash(@new_resource.hash)
  @current_resource.owner(@new_resource.owner)
  @current_resource.group(@new_resource.group)
  @current_resource.mode(@new_resource.mode)
end

use_inline_resources if defined?(use_inline_resources)

def whyrun_supported?
  true
end

def create_collection_from_resource(res)
  fail(
    ArgumentError,
    printf('entries not of type Array, instead got %s', res.entries.inspect),
    caller
  ) unless res.entries.is_a?(Array)
  KnownHostFile::Create.create_user_known_host_entries(res.entries)
end

def write_entries(entries, res)
  Chef::Log.debug "Updating file #{res.path}"
  f = file "#{res.name}-update" do
    path res.path
    action :create
    content "#{entries}"
    backup false
    owner res.owner if res.owner
    group res.group if res.group
    mode res.mode
    notifies(
      :run,
      "ruby_block[#{res.name}-test-if-hash]",
      :delayed
    )
  end

  Chef::Log.debug "Test if we should hash file #{res.path}"
  ruby_block "#{res.name}-test-if-hash" do
    block do
      hash_entries(res, res.hash)
    end
    action :nothing
  end
end

def hash_entries(res, hash)
  ruby_block "#{res.name}-hash-keys" do
    action :nothing
    block do
      `ssh-keygen -f #{res.path} -H`
    end
    notifies(
      :delete,
      "file[#{res.name}-old-cleanup]",
      :delayed
    )
  end if hash

  file "#{res.name}-old-cleanup" do
    path "#{res.path}.old"
    action :nothing
  end
end

action :create do
  ruby_block "#{new_resource.name}-entries" do
    block do
      write_entries(create_collection_from_resource(new_resource), new_resource)
    end
    action :run
  end
end

action :append do
  Chef::Log.debug "Create file #{new_resource.path} if missing"
  f = file "#{new_resource.name}-create" do
    path new_resource.path
    action :create_if_missing
    backup false
    owner new_resource.owner if new_resource.owner
    group new_resource.group if new_resource.group
    mode new_resource.mode
  end

  ruby_block "#{new_resource.name}-entries" do
    block do
      Chef::Log.debug "Read existing entries from #{new_resource.path}"
      entries = create_collection_from_resource(new_resource)
      entries = KnownHostFile::Parse
        .filter_existing_entries(entries, new_resource.path)
      write_entries(entries, new_resource)
    end
    action :run
  end
end

action :hash do
  hash_entries(new_resource, true)
end
