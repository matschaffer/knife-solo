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
    assert_raises KnifeSolo::KitchenCommand::OutOfKitchenError do
      cmd = DummyKitchenCommand.new
      suppress_knife_error_output cmd
      cmd.run
    end
  end

  def test_runs_when_in_a_kitchen
    Dir.chdir(@kitchen) do
      DummyKitchenCommand.new.run
    end
  end
end
