#!/usr/bin/env ruby
require_relative './ssh_known_hosts'


module ParseSshKnownHosts
  include SshKnownHosts

  @regexEntry = Regexp.new('([^\s]+) ([a-z0-9-]+) ([0-9A-Za-z/+]+[=]+)')

  def parse_entry_host(host_entry)
    Host.fromString(host_entry)
  end

  def parse_known_hosts_entry(host, type, key)
    key = HostKey.new(key, type)
    host_entry = HostEntry.new( parse_entry_host(host),key )
    host_entry
  end

  def parse_known_host_string(str)
      str.scan(@regexEntry)
  end

  def from_file(hosts_file)
    # Check we can read the file
    raise "File #{hosts_file} not readable" unless File.readable?(hosts_file)
    f = File.open(hosts_file, 'rb')

    host_entries = []
    # iterate through the file line by line
    f.each { |line|
      parse_known_host_string(line).each do |host, type, key|
        entry = parse_known_hosts_entry(host, type, key)
        host_entries.push(entry)
      end
    }
    f.close
    HostEntriesCollection.new(host_entries)
  end
end

include ParseSshKnownHosts
