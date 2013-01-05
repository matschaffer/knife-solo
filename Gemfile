source :rubygems
gemspec

group :test do
  gem 'parallel'
  gem 'minitest', :require => 'minitest/autorun'
  gem 'mocha', :require => 'mocha/setup'
end

group :development, :test do
  gem 'debugger',   :platforms => :mri_19
  gem 'ruby-debug', :platforms => :mri_18
  gem 'fog'
  gem 'pry'
end
