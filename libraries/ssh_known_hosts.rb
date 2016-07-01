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
      self.new(domains, ips)
    end

    def initialize(domains, ips)
      @domains = domains.uniq.sort
      @ips = ips.uniq.sort
    end

    def domains
      @domains
    end

    def ips
      @ips
    end

    def to_s
      host = self.domains + self.ips
      host.join(',')
    end
  end


# Host key class for a value object

  class HostKey
    def self.fromParts(key, type)
      if type == 'rsa' || type == 'dsa'
        key_type = "ssh-#{type}"
      else
        key_type = type
      end
      self.new(key, type)
    end

    def initialize(key, type)
      @type = type
      @key = key
    end

    def type
      @type
    end

    def key
      @key
    end

    def to_s
      "#{self.type} #{self.key}"
    end
  end

  class HostEntry
    def initialize(host, key)
      raise 'Argument error not of type Host' unless host.kind_of?(Host)
      raise 'Argument error not of type HostKey' unless key.kind_of?(HostKey)
      @host = host
      @key = key
    end

    def compare(host_entry)
      host_entry.key.to_s == self.key.to_s
    end

    def merge(host_entry)
      raise 'Argument error not of type HostEntry' unless host_entry.kind_of?(HostEntry)
      domains = self.host.domains + host_entry.host.domains
      ips = self.host.ips + host_entry.host.ips
      host = Host.new(domains, ips)
      HostEntry.new(host, self.key)
    end

    def host
      @host
    end

    def key
      @key
    end

    def to_s
      "#{self.host} #{self.key}"
    end
  end

  class HostEntriesCollection
    def initialize(entries)
      @host_entries = HostEntriesCollection.resolve(entries)
    end

    def merge(entries)
      raise 'Argument error not of type HostEntriesCollection' unless entries.kind_of?(HostEntriesCollection)

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
        raise "Host entry: #{host_entry.inspect}" unless host_entry.kind_of?(HostEntry)
        if existing.has_key?(host_entry.key.key)
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
