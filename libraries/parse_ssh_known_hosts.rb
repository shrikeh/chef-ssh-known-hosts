#!/usr/bin/env ruby
require_relative './ssh_known_hosts'


module ParseSshKnownHosts
  include SshKnownHosts
  def parse_entry_host(host_entry)
    regex = Regexp.new('\d+\.\d+\.\d+\.\d+')
    ips = []
    domains = []
    host_entry.split(',').each do |part|
      if regex.match(part)
        ips.push(part)
      else
        domains.push(part)
      end
    end
    Host.new(domains, ips)
  end

  def parse_known_hosts_entry(host, type, key)
    key = HostKey.new(key, type)
    host_entry = HostEntry.new( parse_entry_host(host),key )
    host_entry
  end

  def from_file(hosts_file)
    # Check we can read the file
    raise "File #{hosts_file} not readable" unless File.readable?(hosts_file)
    f = File.open(hosts_file, 'rb')
    regexp = Regexp.new('([^\s]+) ([a-z0-9-]+) ([0-9A-Za-z/+]+[=]+)')
    host_entries = []
    f.each { |line|
      line.scan(regexp) do |host, type, key|
        entry = parse_known_hosts_entry(host, type, key)
        host_entries.push(entry)
      end
    }
    f.close
    HostEntriesCollection.new(host_entries)
  end
end
include ParseSshKnownHosts
#keys = ParseSshKnownHosts.from_file('test.ssh')
#puts keys
