source 'https://rubygems.org'

group :chef do
  # Chef tools
  gem 'berkshelf', '~> 3.3.0'
  gem 'knife-solo'
  gem 'knife-solo_data_bag'

  # Lock nokogiri to the version shipped with chefdk, to avoid installing it again
  gem 'nokogiri', '< 1.6.6.3'
end

group :chef_development do
  # Automatically run Tests upon file change
  gem 'guard', '~> 2.13.0'
  gem 'guard-rspec', '~> 4.6.4'

  gem 'chefspec', '~> 4.3.0'
  gem 'test-kitchen', '~> 1.4.2'
  gem 'kitchen-vagrant', '~> 0.18.0'
  gem 'kitchen-docker', '~> 2.3.0'
  gem 'foodcritic', '~> 4.0.0'
end
