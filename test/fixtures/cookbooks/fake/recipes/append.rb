#!/usr/bin/env bash

include_recipe 'ssh_user_known_hosts'

node['ssh_known_hosts']['files'].each do |user_known_hosts|
  ssh_user_known_hosts user_known_hosts['file'] do
    entries user_known_hosts['entries']
    owner   user_known_hosts['owner'] if user_known_hosts['owner']
    group   user_known_hosts['group'] if user_known_hosts['group']
    action  :append if user_known_hosts['append']
  end unless node['ssh_known_hosts'].nil?
end
