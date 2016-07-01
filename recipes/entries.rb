#!/usr/bin/env ruby
#
# Cookbook Name:: ssh_known_hosts
# Recipe:: default
#
# Copyright (c) 2015 The Authors, All Rights Reserved.



ssh_user_known_hosts_entries node['ssh_known_hosts']['file'] do
  entries node['ssh_known_hosts']['entries']
end
