require 'test_helper'

require 'knife-solo/kitchen_command'

require 'chef/knife'
require 'chef/knife/kitchen'

class DummyKitchenCommand < Chef::Knife
  include KnifeSolo::KitchenCommand
end

class KitchenCommandTest < TestCase
  def setup
    @kitchen = 'testkitchen'
    knife_command(Chef::Knife::Kitchen, @kitchen).run
  end

  def teardown
    FileUtils.rm_rf(@kitchen)
  end

  def test_barks_outside_of_the_kitchen
    assert_raises KnifeSolo::KitchenCommand::OutOfKitchenError do
      command.run
    end
  end

  def test_runs_when_in_a_kitchen
    Dir.chdir(@kitchen) do
      command.run
    end
  end

  def command(*args)
    knife_command(DummyKitchenCommand, *args)
  end
end
