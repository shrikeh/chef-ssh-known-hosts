#!/usr/bin/env ruby
# Module for various value objects describing parts of a known_host file
module SshUserKnownHosts
  require 'forwardable'
  # Describes a host (IP, domain) for a host entry
  class Host
    require 'ipaddress'

    include Enumerable
    extend Forwardable
    def_delegators :hosts, :each, :<<

    def self.from_string(str)
      new(str.split(','))
    end

    def filtered(remove)
      remove.each do |_host|
      end
    end

    def initialize(hosts)
      @ips = []
      @domains = []
      hosts.uniq.each do |host|
        filter_host(host)
      end
    end

    attr_reader :domains

    attr_reader :ips

    def to_a
      hosts
    end

    def to_s
      hosts.map(&:to_s).join(',')
    end

    def hosts
      domains + ips
    end

    private

    def filter_host(host)
      if IPAddress.valid? host.to_s
        @ips.push(IPAddr.new(host.to_s))
      else
        @domains.push(host)
      end
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
      validate_host(host)
      validate_key(key)
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
      existing_hosts = hosts.hosts
      new_hosts = host_entry.hosts.hosts
      Host.new(existing_hosts + new_hosts)
    end

    def validate_host(host)
      fail(
        ArgumentError,
        'Argument error not of type Host',
        caller
      ) unless host.is_a?(Host)
      @hosts = host
    end

    def validate_key(key)
      fail(
        ArgumentError,
        'Argument error not of type HostKey',
        caller
      ) unless key.is_a?(HostKey)
      @key = key
    end
  end

  # Immutable collection of Host Entry objects for writing to file
  class HostEntriesCollection
    include Enumerable
    extend Forwardable
    def_delegators :sort_entries, :each, :<<

    def initialize(entries)
      @entries = HostEntriesCollection.resolve(entries)
    end

    def merge(collection)
      HostEntriesCollection.validate_collection(collection)

      host_entries = HostEntriesCollection.resolve(
        collection.entries.values,
        @entries
      )
      HostEntriesCollection.new(host_entries.values)
    end

    def to_a
      @entries
    end

    def to_s
      entries = []
      sort_entries.each do |entry|
        entries.push(entry.to_s)
      end
      "#{entries.sort.join("\n")}\n"
    end

    attr_reader :entries

    def self.resolve(entries, existing = {})
      entries.each do |entry|
        unless entry.nil?
          HostEntriesCollection.validate_entry(entry)
          existing[entry.key.key] = merge_host_entry(existing, entry)
        end
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

    def self.validate_entry(entry)
      fail(
        ArgumentError,
        printf('Host entry: %s', entry.inspect),
        caller
      ) unless entry.is_a?(HostEntry)
    end

    def self.validate_collection(collection)
      fail(
        ArgumentError,
        'Argument error not of type HostEntriesCollection',
        caller
      ) unless collection.is_a?(HostEntriesCollection)
    end

    private

    def sort_entries
      @entries.values
    end
  end
end
