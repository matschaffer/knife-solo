require 'rubygems'
require 'test/unit'
require 'bundler'

Bundler.require
Bundler.require(:test)

class TestCase < Test::Unit::TestCase
  def default_test
    super unless self.class == TestCase
  end
end
