require 'test_helper'

require 'knife-solo/kitchen_command'

require 'chef/knife'
require 'chef/knife/kitchen'

class DummyKitchenCommand < Chef::Knife
  include KnifeSolo::KitchenCommand

  def run
    super
  end
end

class KitchenCommandTest < TestCase
  def setup
    @kitchen = 'testkitchen'
    Chef::Knife::Kitchen.new([@kitchen]).run
  end

  def teardown
    FileUtils.rm_rf(@kitchen)
  end

  def test_barks_outside_of_the_kitchen
    dummy_kitchen = DummyKitchenCommand.new
    # silenced as this warning is expected
    dummy_kitchen.stubs(:warn_for_required_file).returns('noop')
    
    assert_raises KnifeSolo::KitchenCommand::OutOfKitchenError, /joe/ do
      dummy_kitchen.run
    end
  end

  def test_runs_when_in_a_kitchen
    Dir.chdir(@kitchen) do
      DummyKitchenCommand.new.run
    end
  end
end
