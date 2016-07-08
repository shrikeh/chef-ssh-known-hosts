#!/usr/bin/env ruby

module SshUserKnownHosts
  require 'forwardable'
  # Describes a host (IP, domain) for a host entry
  class Host
    include Enumerable
    extend Forwardable
    def_delegators :hosts, :each, :<<
    @regex_ipv4_address = Regexp.new('\d+\.\d+\.\d+\.\d+')

    def self.from_string(str)
      ips = []
      domains = []
      str.split(',').each do |part|
        if @regex_ipv4_address.match(part)
          ips.push(part)
        else
          domains.push(part)
        end
      end
      new(domains, ips)
    end

    def initialize(domains, ips)
      @domains = domains.uniq.sort
      @ips = ips.uniq.sort
    end

    attr_reader :domains

    attr_reader :ips

    def to_s
      hosts.join(',')
    end

    private

    def hosts
      domains + ips
    end
  end

  # Host key class for a value object describing a known_host key (type key)
  class HostKey
    def self.from_parts(key, type)
      type = "ssh-#{type}" if type == 'rsa'
      new(key, type)
    end

    def initialize(key, type)
      @type = type
      @key = key
    end

    attr_reader :type

    attr_reader :key

    def to_s
      "#{type} #{key}"
    end
  end

  # Describes a host entry in known_hosts file (host key-type key)
  class HostEntry
    include Enumerable
    extend Forwardable
    def_delegators :@key, :each, :<<

    def initialize(host, key)
      fail(
        ArgumentError,
        'Argument error not of type Host',
        caller
      ) unless host.is_a?(Host)

      fail(
        ArgumentError,
        'Argument error not of type HostKey',
        caller
      ) unless key.is_a?(HostKey)
      @hosts = host
      @key = key
    end

    def compare(host_entry)
      host_entry.key.to_s == key.to_s
    end

    def merge(host_entry)
      fail(
        ArgumentError,
        'Argument error not of type HostEntry',
        caller
      ) unless host_entry.is_a?(HostEntry)

      HostEntry.new(create_host(host_entry), key)
    end

    attr_reader :hosts

    attr_reader :key

    def to_s
      "#{@hosts} #{@key}"
    end

    private

    def create_host(host_entry)
      domains = hosts.domains + host_entry.hosts.domains
      ips = hosts.ips + host_entry.hosts.ips
      Host.new(domains, ips)
    end
  end

  # Immutable collection of Host Entry objects for writing to file
  class HostEntriesCollection
    include Enumerable
    extend Forwardable
    def_delegators :sort_entries, :each, :<<

    def initialize(entries)
      @host_entries = HostEntriesCollection.resolve(entries)
    end

    def merge(collection)
      fail_msg = 'Argument error not of type HostEntriesCollection'
      fail(
        ArgumentError,
        fail_msg,
        caller
      ) unless collection.is_a?(HostEntriesCollection)

      host_entries = HostEntriesCollection.resolve(
        collection.entries.values,
        @host_entries
      )
      HostEntriesCollection.new(host_entries.values)
    end

    def to_s
      entries = []
      sort_entries.each do | entry |
        entries.push(entry.to_s)
      end
      "#{entries.sort.join("\n")}\n"
    end

    def entries
      @host_entries
    end

    def self.resolve(entries, existing = {})
      fail_msg = 'Host entry: %s'
      entries.each do |entry|
        fail(
          ArgumentError,
          printf(fail_msg, entry.inspect),
          caller
        ) unless entry.is_a?(HostEntry)
        existing[entry.key.key] = merge_host_entry(existing, entry)
      end
      existing.rehash
      existing
    end

    def self.merge_host_entry(existing, host_entry)
      if existing.key?(host_entry.key.key)
        host_entry = existing[host_entry.key.key].merge(host_entry)
      end
      host_entry
    end

    private

    def sort_entries
      @host_entries.values
    end
  end
end
