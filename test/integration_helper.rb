require 'rubygems'
require 'bundler/setup'

require 'minitest/parallel'
require 'minitest/autorun'

require 'pathname'
$base_dir = Pathname.new(__FILE__).dirname

require 'support/loggable'
require 'support/ec2_runner'
require 'support/integration_test'

MiniTest::Parallel.processor_count = 5
MiniTest::Unit.runner = EC2Runner.new
