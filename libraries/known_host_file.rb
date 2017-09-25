#!/usr/bin/env ruby
require_relative './known_hosts'

module KnownHostFile
  # Parse existing known_hosts for appending
  module Parse
    module_function

    include KnownHosts

    @regex_entry = Regexp.new('([^\s]+) ([a-z0-9-]+) ([0-9A-Za-z/+]+[=]*)')

    def parse_known_host_string(str)
      str.scan(@regex_entry).map do |part|
        {
          'host' => part[0],
          'type' => part[1],
          'key'  => part[2]
        }
      end
    end

    def check_existing_hosts(hosts, path)
      existing_hosts = []
      hosts.each do |host|
        existing_hosts.push(host) unless keygen_check_host(host, path).nil?
      end
      existing_hosts
    end

    def create_filtered_hosts(hosts, path)
      existing = check_existing_hosts(hosts, path)
      filtered = hosts.to_a - existing
      Host.new(filtered) unless filtered.empty?
    end

    def create_filtered_entry(entry, path)
      filtered_hosts = create_filtered_hosts(entry.hosts, path)
      HostEntry.new(filtered_hosts, entry.key) unless filtered_hosts.nil?
    end

    def check_existing_entries(entries, path)
      filtered_entries = []
      entries.each do |entry|
        filtered_entries.push(create_filtered_entry(entry, path))
      end
      HostEntriesCollection.new(filtered_entries)
    end

    def keygen_check_host(host, path)
      output = `ssh-keygen -F #{host} -f #{path}`.split("\n")
      output[1] unless output.empty?
    end

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

  # Create new host entries from node attributes
  module Create
    module_function

    include KnownHosts

    def validate_entries(entries)
      fail_msg = 'Argument error not of type Array, instead got %s'
      fail(
        ArgumentError,
        printf(fail_msg, entries.class),
        caller
      ) unless entries.is_a?(Array)
    end

    def validate_host_entry(host_entry)
      fail(
        ArgumentError,
        "#{host_entry.inspect}",
        caller
      ) unless host_entry.is_a?(HostEntry)
      host_entry
    end

    def create_user_known_host_entries(entries)
      validate_entries(entries)
      host_entries = []
      entries.each do |entry|
        host_entry = from_parts(entry)
        host_entries.push(validate_host_entry(host_entry))
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
