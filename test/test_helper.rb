require 'rubygems'
require 'test/unit'
require 'bundler'

Bundler.require
Bundler.require(:test)

class TestCase < Test::Unit::TestCase
end
