source 'https://rubygems.org'

group :chef do
  # Chef tools
  gem 'berkshelf', '~> 3.3.0'
  gem 'knife-solo'
  gem 'knife-solo_data_bag'
  gem 'ipaddress'

  # Lock nokogiri to the version shipped with chefdk,
  # to avoid installing it again
  gem 'nokogiri', '< 1.6.6.3'
end

group :chef_development do
  gem 'chefspec', '~> 4.3.0'
  gem 'test-kitchen', '~> 1.4.2'
  gem 'kitchen-vagrant', '~> 0.18.0'
  gem 'kitchen-docker', '~> 2.3.0'
  gem 'foodcritic', '~> 4.0.0'
  gem 'rubocop', '~> 0.34.0'
  gem 'berkshelf'
  gem 'knife-solo'
  gem 'knife-solo_data_bag'
end
