require 'rubygems'
require 'bundler'

Bundler.require
Bundler.require(:test)

require 'minitest/parallel'
require 'minitest/autorun'
require 'mocha'

class TestCase < MiniTest::Unit::TestCase
  def default_test
    super unless self.class == TestCase
  end
end
