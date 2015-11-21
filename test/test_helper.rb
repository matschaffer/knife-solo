require 'rubygems'
require 'bundler/setup'

# Avoids uninitialized constant Chef::Mixin::ShellOut - see https://github.com/chef/chef/pull/4153
require 'chef/version'
if Gem::Requirement.new('>= 12.5.1').satisfied_by? Gem::Version.new(Chef::VERSION)
  require 'chef/mixin/shell_out'
end

require 'coveralls'
Coveralls.wear!

require 'minitest/autorun'
require 'mocha/setup'

require 'support/test_case'
