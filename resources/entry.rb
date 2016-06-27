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

resource_name 'ssh_user_known_hosts_entry'

actions :create
default_action :create

attribute :host, kind_of: String, name_attribute: true
attribute :key, kind_of: String
attribute :key_type, kind_of: String, default: 'rsa'
attribute :port, kind_of: Fixnum, default: 22
attribute :path, kind_of: String, default: '/etc/ssh/known_hosts'

def initialize(*args)
  super
  @action = :create
end
