if defined?(ChefSpec)
  def create_ssh_known_hosts_entry(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:ssh_known_hosts_entry, :create, resource_name)
  end
end
