#!/usr/bin/env ruby
#
# Cookbook Name:: ssh_known_hosts
# Recipe:: default
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

node['ssh_known_hosts']['files'].each do |user_known_hosts|
  ssh_user_known_hosts user_known_hosts['file'] do
    entries user_known_hosts['entries']
    append user_known_hosts['append'] if user_known_hosts['append']
    owner user_known_hosts['owner'] if user_known_hosts['owner']
    group user_known_hosts['group'] if user_known_hosts['group']
  end
end
