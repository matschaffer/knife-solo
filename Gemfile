source :rubygems
gemspec

group :development do
  gem 'irbtools'
end

group :test do
  gem 'parallel'
  gem 'mocha', :require => false
  gem 'minitest', :require => false
end

group :development, :test do
  gem 'debugger',   :platforms => :mri_19
  gem 'ruby-debug', :platforms => :mri_18
  gem 'fog'
  gem 'pry'
end
