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

resource_name 'ssh_user_known_hosts'

actions :create, :hash, :append
# Our default action, can be anything.
default_action :create if defined?(default_action)

attribute :entries, kind_of: Array
attribute :path, kind_of: String, name_attribute: true
attribute :owner, kind_of: [String, Integer]
attribute :group, kind_of: [String, Integer]
attribute :mode, kind_of: [String, Integer], default: '0644'
attribute :hash, kind_of: [TrueClass, FalseClass], default: true
