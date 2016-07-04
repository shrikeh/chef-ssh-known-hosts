#!/usr/bin/env ruby

module SshKnownHosts
  class Host
    @@regexIpAddress = Regexp.new('\d+\.\d+\.\d+\.\d+')

    def self.fromString(str)
      ips = []
      domains = []
      str.split(',').each do |part|
        if @@regexIpAddress.match(part)
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

  # Host key class for a value object

  class HostKey
    def self.fromParts(key, type)
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
      domains = host.domains + host_entry.host.domains
      ips = host.ips + host_entry.host.ips
      host = Host.new(domains, ips)
      HostEntry.new(host, key)
    end

    attr_reader :host

    attr_reader :key

    def to_s
      "#{host} #{key}"
    end
  end

  class HostEntriesCollection
    def initialize(entries)
      @host_entries = HostEntriesCollection.resolve(entries)
    end

    def merge(entries)
      fail_msg = 'Argument error not of type HostEntriesCollection'
      fail fail_msg unless entries.is_a?(HostEntriesCollection)

      host_entries = HostEntriesCollection.resolve(entries.entries.values, self.entries)
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
      entries.each do |host_entry|
        fail "Host entry: #{host_entry.inspect}" unless host_entry.is_a?(HostEntry)
        if existing.key?(host_entry.key.key)
          host_entry = existing[host_entry.key.key].merge(host_entry)
        end
        existing[host_entry.key.key] = host_entry
      end
      existing.rehash
      existing
    end

    # def compare(first, second)
    #   if first.compare(second)
    #     return first.merge(second)
    #   end
    #   false
    # end
  end
end
