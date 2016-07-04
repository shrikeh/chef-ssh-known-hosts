#!/usr/bin/env ruby

module SshKnownHosts
  # Describes a host (IP, domain) for a host entry
  class Host
    @regex_ip_address = Regexp.new('\d+\.\d+\.\d+\.\d+')

    def self.from_string(str)
      ips = []
      domains = []
      str.split(',').each do |part|
        if @regex_ip_address.match(part)
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
      host = domains + ips
      host.join(',')
    end
  end

  # Host key class for a value object describing a known_host key (type key)
  class HostKey
    def self.from_parts(key, type)
      type = "ssh-#{type}" if type == 'rsa' || type == 'dsa'
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
    def initialize(host, key)
      fail 'Argument error not of type Host' unless host.is_a?(Host)
      fail 'Argument error not of type HostKey' unless key.is_a?(HostKey)
      @host = host
      @key = key
    end

    def compare(host_entry)
      host_entry.key.to_s == key.to_s
    end

    def merge(host_entry)
      fail_msg = 'Argument error not of type HostEntry'
      fail fail_msg unless host_entry.is_a?(HostEntry)

      HostEntry.new(create_host(host_entry), key)
    end

    attr_reader :host

    attr_reader :key

    def to_s
      "#{host} #{key}"
    end

    private

    def create_host(host_entry)
      domains = host.domains + host_entry.host.domains
      ips = host.ips + host_entry.host.ips
      Host.new(domains, ips)
    end
  end

  # Immutable collection of Host Entry objects for writing to file
  class HostEntriesCollection
    def initialize(entries)
      @host_entries = HostEntriesCollection.resolve(entries)
    end

    def merge(entries)
      fail_msg = 'Argument error not of type HostEntriesCollection'
      fail fail_msg unless entries.is_a?(HostEntriesCollection)

      host_entries = HostEntriesCollection.resolve(
        entries.entries.values,
        self.entries
      )
      HostEntriesCollection.new(host_entries.values)
    end

    def to_s
      entries = []
      @host_entries.values.each do |entry|
        entries.push(entry.to_s)
      end
      entries.sort.join("\n")
    end

    def entries
      @host_entries
    end

    def self.resolve(entries, existing = {})
      fail_msg = 'Host entry: %s'
      entries.each do |entry|
        fail printf(fail_msg, entry.inspect) unless entry.is_a?(HostEntry)
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

    # def compare(first, second)
    #   if first.compare(second)
    #     return first.merge(second)
    #   end
    #   false
    # end
  end
end
