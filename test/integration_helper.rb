require 'test_helper'
require 'pathname'

require 'support/loggable'
require 'support/ec2_runner'
require 'support/integration_test'

$base_dir = Pathname.new(__FILE__).dirname

MiniTest::Parallel.processor_count = 5
MiniTest::Unit.runner = EC2Runner.new
