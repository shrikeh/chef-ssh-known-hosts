#!/usr/bin/env ruby

module SshKnownHosts
  class Host
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
      host.join(', ')
    end
  end

  class HostKey
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
      @host = host
      @key = key
    end

    def compare(host_entry)
      host_entry.key.to_s == self.key.to_s
    end

    def merge(host_entry)
      raise "Argument error not of type HostEntry" unless host_entry.kind_of?(HostEntry)
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
      @host_entries = {}
      entries.uniq.each do |host_entry|
        @host_entries.each do |key, entry|
          if host_entry.compare(entry)
            host_entry = entry.merge(host_entry)
            break
          end
        end
        @host_entries[host_entry.key.to_s] = host_entry
      end
    end

    def to_s
      entries = []
      @host_entries.values.each do |entry|
        entries.push(entry.to_s)
      end
      entries.sort.join("\n")
    end
  end
end
